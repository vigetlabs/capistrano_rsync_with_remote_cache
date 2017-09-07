require 'capistrano/recipes/deploy/strategy/remote'
require 'fileutils'

module Capistrano
  module Deploy
    module Strategy
      class RsyncWithRemoteCache < Remote

        class InvalidCacheError < Exception; end

        CONFIG = {
          :subversion => {:url_command => "svn info . | sed -n \'s/URL: //p\'",                      :exclusions => '.svn*'},
          :git        => {:url_command => "git config remote.origin.url",                            :exclusions => '.git*'},
          :mercurial  => {:url_command => "hg showconfig paths.default",                             :exclusions => '.hg*'},
          :bzr        => {:url_command => "bzr info | grep parent | sed \'s/^.*parent branch: //\'", :exclusions => '.bzr*'}
        }

        def self.default_attribute(attribute, default_value)
          define_method(attribute) { configuration[attribute] || default_value }
        end

        default_attribute :rsync_options, '-az --delete-excluded'
        default_attribute :local_cache, '.rsync_cache'
        default_attribute :repository_cache, 'cached-copy'

        def deploy!
          update_local_cache
          update_remote_cache
          copy_remote_cache
        end

        def update_local_cache
          unless system(command)
            system("rm -rf #{local_cache_path}")
            system(command)
          end
          mark_local_cache
        end

        def update_remote_cache
          finder_options = {:except => { :no_release => true }}
          find_servers(finder_options).each {|s| sync_source_to(s) }
        end

        def copy_remote_cache
          run_rsync('-a', '--delete', "#{repository_cache_path}/", "#{configuration[:release_path]}/")
        end

        def sync_source_to(server)
          run_rsync(rsync_options, exclusion_options, "--rsh='#{ssh_command_for(server)}'", "'#{local_cache_path}/'", "#{rsync_host(server)}:#{repository_cache_path}/", :local => true)
        end

        def mark_local_cache
          File.open(File.join(local_cache_path, 'REVISION'), 'w') {|f| f << revision }
        end

        def default_exclusions
          Array(CONFIG[configuration[:scm]].fetch(:exclusions, []))
        end

        def exclusion_options
          copy_exclude.map {|f| "--exclude='#{f}'" }.join(' ')
        end

        def ssh_port(server)
          server.port || ssh_options[:port] || configuration[:port]
        end

        def ssh_command_for(server)
          port = ssh_port(server)
          port.nil? ? "ssh" : "ssh -p #{port}"
        end

        def local_cache_path
          File.expand_path(local_cache)
        end

        def repository_cache_path
          File.join(shared_path, repository_cache)
        end

        def repository_url
          `cd #{local_cache_path} && #{CONFIG[configuration[:scm]][:url_command]}`.strip
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

        def command
          if local_cache_valid?
            source.sync(revision, local_cache_path)
          elsif !local_cache_exists?
            "mkdir -p #{local_cache_path} && #{source.checkout(revision, local_cache_path)}"
          else
            raise InvalidCacheError, "The local cache exists but is not valid (#{local_cache_path})"
          end
        end

        private

        def copy_exclude
          default_exclusions + Array(configuration.fetch(:copy_exclude, []))
        end

        def run_rsync(*args)
          options = args.last.is_a?(Hash) ? args.pop : {}

          command_options = args.select {|a| a.strip.length > 0 }.join(' ')
          command         = "rsync #{command_options}"

          options.fetch(:local, false) ? system(command) : run(command)
        end

      end
    end
  end
end
