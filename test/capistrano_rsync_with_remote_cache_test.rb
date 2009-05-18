# This test suite was written way after the code, back when the author didn't do TDD consistently.
# Also, the code does a lot of things with external servers and services, so there's a lot of mocking.
# Therefore, this suite is nearly impossible to follow in places. Sorry.

require 'test_helper'

class CapistranoRsyncWithRemoteCacheTest < Test::Unit::TestCase
  def stub_configuration(hash)
    @rwrc.expects(:configuration).at_least_once.returns(hash)
  end

  def stub_creation_of_new_local_cache
    File.expects(:exists?).with('.rsync_cache').times(2).returns(false)
    File.expects(:directory?).with(File.dirname('.rsync_cache')).returns(false)
    Dir.expects(:mkdir).with(File.dirname('.rsync_cache'))
    source_stub = stub()
    source_stub.expects(:checkout)
    @rwrc.expects(:source).returns(source_stub)
  end
  
  context 'RsyncWithRemoteCache' do
    setup do
      @rwrc = Capistrano::Deploy::Strategy::RsyncWithRemoteCache.new
      logger_stub = stub()
      logger_stub.stubs(:trace)
      @rwrc.stubs(:logger).returns(logger_stub)
    end

    should 'deploy!' do
      stub_configuration(:deploy_to => 'deploy_to', :release_path => 'release_path', :scm => :subversion)
      @rwrc.stubs(:shared_path).returns('shared')

      # Step 1: Update the local cache.
      @rwrc.expects(:command).returns('command')
      @rwrc.expects(:system).with('command')
      revision_file_stub = stub()
      revision_file_stub.expects(:puts)
      File.expects(:open).with(File.join('.rsync_cache', 'REVISION'), 'w').yields(revision_file_stub)

      # Step 2: Update the remote cache.
      server_stub = stub(:host => 'host')
      @rwrc.expects(:system).with("rsync -az --delete .rsync_cache/ host:shared/cached-copy/")
      @rwrc.expects(:find_servers).returns([server_stub])

      # Step 3: Copy the remote cache into place.
      @rwrc.expects(:mark).returns('mark')
      @rwrc.expects(:run).with("rsync -a --delete shared/cached-copy/ release_path/ && mark")

      @rwrc.deploy!
    end

    should 'check!' do
      configuration = {:releases_path => 'releases_path', :deploy_to => 'deploy_to'}
      configuration.stubs(:invoke_command)
      @rwrc.expects(:configuration).at_least_once.returns(configuration)

      source_stub = stub(:command => 'command')
      @rwrc.stubs(:source).returns(source_stub)

      @rwrc.check!
    end

    context 'repository_cache' do
      setup do
        @rwrc.expects(:shared_path).returns('shared')
      end

      should 'return specified cache if present in configuration' do
        stub_configuration(:repository_cache => 'cache')
        assert_equal 'shared/cache', @rwrc.send(:repository_cache)
      end

      should 'return default cache if not present in configuration' do
        stub_configuration(:repository_cache => nil)
        assert_equal 'shared/cached-copy', @rwrc.send(:repository_cache)
      end
    end

    context 'local_cache' do
      should 'return specified cache if present in configuration' do
        stub_configuration(:local_cache => 'cache')
        assert_equal 'cache', @rwrc.send(:local_cache)
      end

      should 'return default cache if not present in configuration' do
        stub_configuration(:local_cache => nil)
        assert_equal '.rsync_cache', @rwrc.send(:local_cache)
      end
    end

    context 'rsync_options' do
      should 'return specified options if present in configuration' do
        stub_configuration(:rsync_options => 'options')
        assert_equal 'options', @rwrc.send(:rsync_options)
      end

      should 'return default options if not present in configuration' do
        stub_configuration(:rsync_options => nil)
        assert_equal '-az --delete', @rwrc.send(:rsync_options)
      end
    end

    context 'rsync_host' do
      setup do
        @server_stub = stub(:host => 'host')
      end

      should 'prefix user if present in configuration' do
        stub_configuration(:user => 'user')
        assert_equal 'user@host', @rwrc.send(:rsync_host, @server_stub)
      end

      should 'not prefix user if not present in configuration' do
        stub_configuration(:user => nil)
        assert_equal 'host', @rwrc.send(:rsync_host, @server_stub)
      end
    end

    context 'command' do
      should 'purge and recreate local cache if it detects subversion info has changed' do
        stub_configuration(:scm => :subversion, :repository => 'repository')        

        svn_info_stub = stub()
        svn_info_stub.expects(:gets).returns("URL: url\n")
        svn_info_stub.expects(:close)
        IO.expects(:popen).with("svn info .rsync_cache | sed -n 's/URL: //p'").returns(svn_info_stub)

        FileUtils.expects(:rm_rf).with('.rsync_cache')

        stub_creation_of_new_local_cache

        @rwrc.send(:command)
      end

      should 'not attempt to purge and recreate local cache that does not exist' do
        stub_configuration(:scm => :subversion, :repository => 'repository')        

        svn_info_stub = stub()
        svn_info_stub.expects(:gets).returns(nil)
        svn_info_stub.expects(:close)
        IO.expects(:popen).with("svn info .rsync_cache | sed -n 's/URL: //p'").returns(svn_info_stub)

        FileUtils.expects(:rm_rf).with('.rsync_cache').never

        stub_creation_of_new_local_cache

        @rwrc.send(:command)
      end

      should 'not attempt to purge and recreate local cache if the scm is not subversion' do
        stub_configuration(:scm => :git, :repository => 'repository')        

        IO.expects(:popen).with("svn info .rsync_cache | sed -n 's/URL: //p'").never
        FileUtils.expects(:rm_rf).with('.rsync_cache').never

        stub_creation_of_new_local_cache

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

      should 'create local cache if it does not exist' do
        stub_creation_of_new_local_cache

        @rwrc.send(:command)
      end
    end
  end
end
