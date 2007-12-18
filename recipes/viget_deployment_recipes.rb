require 'rubygems'
require 'yaml'
require 'erb'
require 'uri'
require 'tinder'
require 'capistrano/ext/multistage'

depend :local, :gem, 'capistrano', '>=2.0.0'
depend :local, :gem, 'capistrano-ext', '>=1.2.0'
depend :local, :gem, 'tinder', '>=0.1.4'

namespace :deploy do

  before "deploy", "viget:lockout:check"
  before "deploy:migrations", "viget:lockout:check"
  before "deploy:update_code", "viget:db:dump"
  after "deploy:update_code", "viget:deploy:post_update_code"
  after "deploy", "viget:deploy:campfire"
  after "deploy:migrations", "viget:deploy:campfire"

  after "multistage:ensure", "viget:config:environment"

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

namespace :viget do
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
    task :post_update_code do
      run "cp #{release_path}/config/database.yml-sample #{release_path}/config/database.yml"
      run "cp #{release_path}/config/mongrel_cluster.yml-#{stage} #{release_path}/config/mongrel_cluster.yml"
      unless fetch(:symlinks,nil).nil?
        fetch(:symlinks).each do |link|
          run "rm -rf #{release_path}/#{link} && ln -nfs #{shared_path}/#{link} #{release_path}/#{link}"
        end
      end
    end

    desc '[internal] Announces deployments in one or more Campfire rooms.'
    task :campfire do
      campfires = fetch(:campfires,nil)
      notify = fetch(:campfire_notify,nil)
      unless campfires.nil? || notify.nil?
        notify.each do |name|
          config = campfires[name]
          campfire = Tinder::Campfire.new(config[:domain], :ssl => config[:ssl])
          if campfire.login(config[:email], config[:password])
            if room = campfire.find_room_by_name(config[:room])
              logger.debug "sending message to #{config[:room]} on #{name.to_s} Campfire"
              message = "[CAP] %s just deployed revision %s from %s" % [
                ENV['USER'],
                current_revision,
                URI.parse(fetch(:repository)).path
              ]
              if stage = fetch(:stage)
                message << " to #{stage}"
              end
              room.speak "#{message}."
            else
              logger.debug "Campfire #{name.to_s} room #{config[:room]} not found"
            end
          else
            logger.debug "Campfire #{name.to_s} email and/or password incorrect"
          end
        end
      end
    end
  end
  
  namespace :config do
    desc '[internal] Sets the rails_env configuration variable to match the selected stage.'
    task :environment do
      set :rails_env, fetch(:stage).to_s
    end
  end
end
