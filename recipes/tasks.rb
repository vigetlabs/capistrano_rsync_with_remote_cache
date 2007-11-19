require 'yaml'
require 'erb'
require 'capistrano/ext/multistage'

Capistrano::Configuration.instance(:must_exist).load do
  abort "This version of vl_capistrano is not compatible with Capistrano 1.x." unless respond_to?(:namespace)

  namespace :deploy do

    before "deploy", "vl:lockout:check"
    before "deploy:migrations", "vl:lockout:check"
    before "deploy:update_code", "vl:db:dump"
    after "deploy:update_code", "vl:deploy:post_update_code"
    
    desc 'Start the application servers.'
    task :start, :roles => :app do
      unless fetch(:timezone,nil).nil?
        run "cd #{current_path} && TZ=#{fetch(:timezone)} mongrel_rails cluster::start --clean"
      else
        run "cd #{current_path} && mongrel_rails cluster::start --clean"
      end
    end
    
    desc 'Restart the application servers.'
    task :restart, :roles => :app, :except => { :no_release => true } do
      deploy::stop
      sleep 1
      deploy::start
    end

    desc 'Stop the application servers.'
    task :stop, :roles => :app do
      run "cd #{current_path} && mongrel_rails cluster::stop"
    end

    desc 'Present a maintenance page to visitors.'
    web.task :disable, :roles => :web, :except => { :no_release => true } do
      on_rollback { run "rm #{shared_path}/system/maintenance.html" }
      reason = ENV['REASON']
      deadline = ENV['UNTIL']
      if File.exists?("./app/views/layouts/maintenance.erb")
        template = File.read("./app/views/layouts/maintenance.erb")
      else
        template = File.read(File.join(File.dirname(__FILE__), "templates", "maintenance.erb"))
      end
      result = ERB.new(template).result(binding)
      put result, "#{shared_path}/system/maintenance.html", :mode => 0644
    end
    
    desc 'Updates the symlink to the most recently deployed version.'
    task :symlink, :except => { :no_release => true } do
      on_rollback { run "rm -f #{current_path}; ln -s #{previous_release.gsub(/^#{deploy_to}\//,'')} #{current_path}; true" }
      run "rm -f #{current_path} && ln -s #{latest_release.gsub(/^#{deploy_to}\//,'')} #{current_path}"
    end
  end

  namespace :vl do
    namespace :lockout do
      desc 'Lock out deployment. Specify reason with REASON=xyz'
      task :add, :roles => :app do
        fn="LOCKOUT.#{stage}"
        File.delete(fn) rescue nil
        lf=File.new(fn,'w')
        lf.puts("#{ENV['USER']}: #{ENV['REASON']}")
        lf.close
        system "svn add #{fn} && svn ci -m 'Lockout added' #{fn}"
      end

      desc 'Remove any existing lockout.'
      task :remove, :roles => :app do
        system "svn remove LOCKOUT.#{stage} && svn ci -m 'Lockout removed' ."
      end

      desc '[internal] Checks for lockouts and aborts if any are found.'
      task :check do
        lockouts = IO.readlines("LOCKOUT.#{stage}") rescue nil
        unless lockouts.nil?
          puts "\n*** LOCKOUT ***\n\n"
          lockouts.each {|l| puts l}
          puts "\n*** LOCKOUT ***\n\n"
          exit
        end
      end
    end

    namespace :db do
      desc 'Dump the database for the given stage.'
      task :dump, :roles => :db do
        begin
          dbc=YAML.load(File.open('config/database.yml'))[stage.to_s]
          logger.debug "dumping #{stage} database"
          run "mysqldump -h#{dbc['host']} -u#{dbc['username']} -p#{dbc['password']} #{dbc['database']} >#{deploy_to}/dump.sql"
        rescue NoMethodError
          raise RuntimeError,"No such stage: #{stage}"
        end
      end

      desc 'Restore the database for the given stage.'
      task :restore, :roles => :db do
        begin
          dbc=YAML.load(File.open('config/database.yml'))[stage]
          logger.debug "restoring #{stage} database from dump"
          run("mysql -h#{dbc['host']} -u#{dbc['username']} -p#{dbc['password']} #{dbc['database']} <#{deploy_to}/dump.sql") do |channel,stream,data|
            unless data.empty?
              raise RuntimeError,"Couldn't restore #{stage} database from dump"
            end
          end
        rescue NoMethodError
          raise RuntimeError,"No such stage: #{stage}"
        end
      end
    end
    
    namespace :deploy do
      desc '[internal] Creates Viget-specific config files and any symlinks specified in the configuration.'
      task :post_update_code, :roles => :app do
        run "cp #{release_path}/config/database.yml-sample #{release_path}/config/database.yml"
        run "cp #{release_path}/config/mongrel_cluster.yml-#{stage} #{release_path}/config/mongrel_cluster.yml"
        unless fetch(:symlinks,nil).nil?
          fetch(:symlinks).each do |link|
            run "rm -rf #{release_path}/#{link} && ln -nfs #{shared_path}/#{link} #{release_path}/#{link}"
          end
        end
      end
    end
  end
end
