require 'capistrano/recipes/deploy/strategy/remote'
require 'fileutils'

module Capistrano
  module Deploy
    module Strategy
      class RsyncWithRemoteCache < Remote

        INFO_COMMANDS = {
          :subversion => "svn info . | sed -n \'s/URL: //p\'",
          :git        => "git config remote.origin.url",
          :mercurial  => "hg showconfig paths.default",
          :bzr        => "bzr info | grep parent | sed \'s/^.*parent branch: //\'"
        }

        # The deployment method itself, in three major steps: update the local cache, update the remote
        # cache, and copy the remote cache into place.
        def deploy!

          # Step 1: Update the local cache.
          system(command)
          File.open(File.join(local_cache, "REVISION"), "w") { |file| file.puts(revision) }

          # Step 2: Update the remote cache.
          logger.trace "copying local cache to remote"
          find_servers(:except => { :no_release => true }).each do |server|
            system("rsync #{rsync_options} --rsh='ssh -p #{ssh_port}' #{local_cache}/ #{rsync_host(server)}:#{repository_cache}/")
          end

          # Step 3: Copy the remote cache into place.
          run("rsync -a --delete #{repository_cache}/ #{configuration[:release_path]}/ && #{mark}")
        end

        # Defines commands that should be checked for by deploy:check. These include the SCM command
        # on the local end, and rsync on both ends. Note that the SCM command is not needed on the
        # remote end.
        def check!
          super.check do |check|
            check.local.command(source.command)
            check.local.command('rsync')
            check.remote.command('rsync')
          end
        end

        private

        # Path to the remote cache. We use a variable name and default that are compatible with
        # the stock remote_cache strategy, for easy migration.
        # @return [String] the path to the remote cache
        def repository_cache
          File.join(shared_path, configuration[:repository_cache] || "cached-copy")
        end

        # Path to the local cache. If not specified in the Capfile, we use an arbitrary default.
        # @return [String] the path to the local cache
        def local_cache
          configuration[:local_cache] || ".rsync_cache"
        end

        # Options to use for rsync in step 2. If not specified in the Capfile, we use the default
        # from prior versions.
        # @return [String] the options to be passed to rsync
        def rsync_options
          configuration[:rsync_options] || "-az --delete"
        end

        # Port to use for rsync in step 2. If not specified with (ssh_options) in the Capfile, we
        # use the default well-known port 22.
        # @return [Fixnum] the port to connect to with rsync
        def ssh_port
          ssh_options[:port] || 22
        end

        # Get a hostname to be used in the rsync command.
        # @param [Capistrano::ServerDefinition, #host] the host which rsync will connect to
        # @return [String] the hostname, prefixed with user@ if necessary
        def rsync_host(server)
          if configuration[:user]
            "#{configuration[:user]}@#{server.host}"
          else
            server.host
          end
        end

        # Remove the local cache (so it can be recreated) if the repository URL has changed
        # since the last deployment.
        # TODO: punt in some sensible way if local_cache exists but is a regular file.
        def remove_cache_if_repo_changed
          if INFO_COMMANDS[configuration[:scm]] && File.directory?(local_cache)
            info_command = "cd #{local_cache} && #{INFO_COMMANDS[configuration[:scm]]}"
            cached_repo_url = IO.popen(info_command){|pipe| pipe.readline}.chomp
            if cached_repo_url != configuration[:repository]
              logger.trace "repository has changed; removing old local cache"
              FileUtils.rm_rf(local_cache)
            end
          end
        end

        # Command to get source from SCM on the local side. The local cache is either created,
        # updated, or destroyed and recreated depending on whether it exists and is a cache of
        # the right repository.
        # @return [String] command to either checkout or update the local cache
        def command
          remove_cache_if_repo_changed
          if File.exists?(local_cache) && File.directory?(local_cache)
            logger.trace "updating local cache to revision #{revision}"
            return source.sync(revision, local_cache)
          else
            logger.trace "creating local cache with revision #{revision}"
            File.delete(local_cache) if File.exists?(local_cache)
            Dir.mkdir(File.dirname(local_cache)) unless File.directory?(File.dirname(local_cache))
            return source.checkout(revision, local_cache)
          end
        end
      end
    end
  end
end
