require 'capistrano/recipes/deploy/strategy/remote'
require 'fileutils'

module Capistrano
  module Deploy
    module Strategy
      class RsyncWithRemoteCache < Remote
        
        class InvalidCacheError < Exception; end

        def self.default_attribute(attribute, default_value)
          define_method(attribute) { configuration[attribute] || default_value }
        end

        INFO_COMMANDS = {
          :subversion => "svn info . | sed -n \'s/URL: //p\'",
          :git        => "git config remote.origin.url",
          :mercurial  => "hg showconfig paths.default",
          :bzr        => "bzr info | grep parent | sed \'s/^.*parent branch: //\'"
        }
        
        default_attribute :rsync_options, '-az --delete'
        default_attribute :local_cache, '.rsync_cache'
        default_attribute :repository_cache, 'cached-copy'

        def deploy!
          update_local_cache
          update_remote_cache
          copy_remote_cache
        end
        
        def update_local_cache
          system(command)
          mark_local_cache
        end
        
        def update_remote_cache
          finder_options = {:except => { :no_release => true }}
          find_servers(finder_options).each {|s| system(rsync_command_for(s)) }
        end
        
        def copy_remote_cache
          run("rsync -a --delete #{repository_cache_path}/ #{configuration[:release_path]}/")
        end
        
        def rsync_command_for(server)
          "rsync #{rsync_options} --rsh='ssh -p #{ssh_port}' #{local_cache_path}/ #{rsync_host(server)}:#{repository_cache_path}/"
        end
        
        def mark_local_cache
          File.open(File.join(local_cache_path, 'REVISION'), 'w') {|f| f << revision }
        end
        
        def ssh_port
          ssh_options[:port] || 22
        end
        
        def local_cache_path
          File.expand_path(local_cache)
        end
        
        def repository_cache_path
          File.join(shared_path, repository_cache)
        end
        
        def repository_url
          `cd #{local_cache_path} && #{INFO_COMMANDS[configuration[:scm]]}`.strip
        end
        
        def repository_url_changed?
          repository_url != configuration[:repository]
        end
        
        def remove_local_cache
          logger.trace "repository has changed; removing old local cache from #{local_cache_path}"
          FileUtils.rm_rf(local_cache_path)
        end

        def remove_cache_if_repository_url_changed
          remove_local_cache if repository_url_changed?
        end
        
        def rsync_host(server)
          configuration[:user] ? "#{configuration[:user]}@#{server.host}" : server.host
        end
        
        def local_cache_exists?
          File.exist?(local_cache_path)
        end
        
        def local_cache_valid?
          local_cache_exists? && File.directory?(local_cache_path)
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

        def command
          if local_cache_valid?
            source.sync(revision, local_cache_path)
          elsif !local_cache_exists?
            "mkdir -p #{local_cache_path} && #{source.checkout(revision, local_cache_path)}"
          else
            raise InvalidCacheError, "The local cache exists but is not valid (#{local_cache_path})"
          end
        end
      end
      
    end
  end
end
