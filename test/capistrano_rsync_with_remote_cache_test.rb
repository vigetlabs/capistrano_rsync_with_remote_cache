require 'test_helper'

class CapistranoRsyncWithRemoteCacheTest < Test::Unit::TestCase
  context 'RsyncWithRemoteCache' do
    setup do
      @rwrc = Capistrano::Deploy::Strategy::RsyncWithRemoteCache.new
      # @configuration = {
      #   :local_cache => '',
      #   :release_path => '',
      #   :repository => '',
      #   :repository_cache => '',
      #   :rsync_options => '',
      #   :scm => '',
      #   :user => ''
      # }
      # @rwrc.expects(:configuration).at_least_once.returns(@configuration)

      logger_stub = stub()
      logger_stub.stubs(:trace)
      @rwrc.stubs(:logger).returns(logger_stub)

      # FIXME: this is lame
      class << @rwrc
        def `(cmd)
          '\n'
        end
      end
    end

    should 'deploy!' do
      # # Step 1: Update the local cache.
      # system(command)
      # File.open(File.join(local_cache, "REVISION"), "w") { |f| f.puts(revision) }
      # 
      # # Step 2: Update the remote cache.
      # logger.trace "copying local cache to remote"
      # find_servers(:except => { :no_release => true }).each do |server|
      #   system("rsync #{rsync_options} #{local_cache}/ #{rsync_host(server)}:#{repository_cache}/")
      # end
      # 
      # # Step 3: Copy the remote cache into place.
      # run("rsync -a --delete #{repository_cache}/ #{configuration[:release_path]}/ && #{mark}")
    end

    should 'check!' do
      # super.check do |d|
      #   d.local.command(source.command)
      #   d.local.command('rsync')
      #   d.remote.command('rsync')
      # end
    end

    context 'repository_cache' do
      setup do
        @rwrc.expects(:shared_path).returns('shared')
      end

      should 'return specified cache if present in configuration' do
        @configuration = {:repository_cache => 'cache'}
        @rwrc.expects(:configuration).at_least_once.returns(@configuration)

        assert_equal 'shared/cache', @rwrc.send(:repository_cache)
      end

      should 'return default cache if not present in configuration' do
        @configuration = {:repository_cache => nil}
        @rwrc.expects(:configuration).at_least_once.returns(@configuration)

        assert_equal 'shared/cached-copy', @rwrc.send(:repository_cache)
      end
    end

    context 'local_cache' do
      should 'return specified cache if present in configuration' do
        @configuration = {:local_cache => 'cache'}
        @rwrc.expects(:configuration).at_least_once.returns(@configuration)

        assert_equal 'cache', @rwrc.send(:local_cache)
      end

      should 'return default cache if not present in configuration' do
        @configuration = {:local_cache => nil}
        @rwrc.expects(:configuration).at_least_once.returns(@configuration)

        assert_equal '.rsync_cache', @rwrc.send(:local_cache)
      end
    end

    context 'rsync_options' do
      should 'return specified options if present in configuration' do
        @configuration = {:rsync_options => 'options'}
        @rwrc.expects(:configuration).at_least_once.returns(@configuration)

        assert_equal 'options', @rwrc.send(:rsync_options)
      end

      should 'return default options if not present in configuration' do
        @configuration = {:rsync_options => nil}
        @rwrc.expects(:configuration).at_least_once.returns(@configuration)

        assert_equal '-az --delete', @rwrc.send(:rsync_options)
      end
    end

    context 'rsync_host' do
      setup do
        @server_stub = stub(:host => 'host')
      end

      should 'prefix user if present in configuration' do
        @configuration = {:user => 'user'}
        @rwrc.expects(:configuration).at_least_once.returns(@configuration)

        assert_equal 'user@host', @rwrc.send(:rsync_host, @server_stub)
      end

      should 'not prefix user if not present in configuration' do
        @configuration = {:user => nil}
        @rwrc.expects(:configuration).at_least_once.returns(@configuration)

        assert_equal 'host', @rwrc.send(:rsync_host, @server_stub)
      end
    end

    context 'command' do
      should 'remove local cache dir if it detects subversion info has changed' do
        @configuration = {:scm => :subversion}
        @rwrc.expects(:configuration).at_least_once.returns(@configuration)

        @rwrc.expects(:`).returns('something else')
        @rwrc.expects(:system) # with something else

        File.expects(:exists?).with('.rsync_cache').times(2).returns(false)
        File.expects(:directory?).with(File.dirname('.rsync_cache')).returns(false)
        Dir.expects(:mkdir).with(File.dirname('.rsync_cache'))

        source_stub = stub()
        source_stub.expects(:checkout)
        @rwrc.expects(:source).returns(source_stub)

        @rwrc.send(:command)

      end

      should 'update local cache if it exists' do
        File.expects(:exists?).with('.rsync_cache').returns(true)
        File.expects(:directory?).with('.rsync_cache').returns(true)
        source_stub = stub()
        source_stub.expects(:sync)
        @rwrc.expects(:source).returns(source_stub)

        @rwrc.send(:command)
      end

      should 'update local cache if it does not exist' do
        File.expects(:exists?).with('.rsync_cache').times(2).returns(false)
        File.expects(:directory?).with(File.dirname('.rsync_cache')).returns(false)
        Dir.expects(:mkdir).with(File.dirname('.rsync_cache'))
        source_stub = stub()
        source_stub.expects(:checkout)
        @rwrc.expects(:source).returns(source_stub)

        @rwrc.send(:command)
      end
    end
  end
end
