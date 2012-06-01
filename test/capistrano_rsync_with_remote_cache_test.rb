require 'rubygems'
require 'test/unit'
require 'mocha'
require 'shoulda'
require 'matchy'
require 'tmpdir'

require 'capistrano/recipes/deploy/strategy/rsync_with_remote_cache'

class CapistranoRsyncWithRemoteCacheTest < Test::Unit::TestCase
  
  context "An instance of the CapistranoRsyncWithRemoteCache class" do
    setup { @strategy = Capistrano::Deploy::Strategy::RsyncWithRemoteCache.new }

    should "know the default rsync options" do
      @strategy.rsync_options.should == '-az --delete'
    end
    
    should "allow overriding of the rsync options" do
      @strategy.stubs(:configuration).with().returns(:rsync_options => 'new_opts')
      @strategy.rsync_options.should == 'new_opts'
    end

    should "know the default local cache name" do
      @strategy.local_cache.should == '.rsync_cache'
    end
    
    should "know the local cache name if it has been configured" do
      @strategy.stubs(:configuration).with().returns(:local_cache => 'cache')
      @strategy.local_cache.should == 'cache'
    end
    
    should "know the cache path" do
      @strategy.stubs(:local_cache).with().returns('cache_dir')
      File.expects(:expand_path).with('cache_dir').returns('local_cache_path')
      
      @strategy.local_cache_path.should == 'local_cache_path'
    end
    
    should "know the repository URL for a subversion repository" do
      @strategy.stubs(:local_cache_path).with().returns('cache_path')
      @strategy.stubs(:configuration).with().returns(:scm => :subversion)
      @strategy.expects(:`).with("cd cache_path && svn info . | sed -n \'s/URL: //p\'").returns("svn_url\n")
      @strategy.repository_url.should == 'svn_url'
    end
    
    should "know the repository URL for a git repository" do
      @strategy.stubs(:local_cache_path).with().returns('cache_path')
      @strategy.stubs(:configuration).with().returns(:scm => :git)
      @strategy.expects(:`).with("cd cache_path && git config remote.origin.url").returns("git_url\n")
      @strategy.repository_url.should == 'git_url'
    end
    
    should "know the repository URL for a mercurial repository" do
      @strategy.stubs(:local_cache_path).with().returns('cache_path')
      @strategy.stubs(:configuration).with().returns(:scm => :mercurial)
      @strategy.expects(:`).with("cd cache_path && hg showconfig paths.default").returns("hg_url\n")
      @strategy.repository_url.should == 'hg_url'
    end
    
    should "know the repository URL for a bzr repository" do
      @strategy.stubs(:local_cache_path).with().returns('cache_path')
      @strategy.stubs(:configuration).with().returns(:scm => :bzr)
      @strategy.expects(:`).with("cd cache_path && bzr info | grep parent | sed \'s/^.*parent branch: //\'").returns("bzr_url\n")
      @strategy.repository_url.should == 'bzr_url'
    end
    
    should "know that the repository URL has not changed" do
      @strategy.stubs(:repository_url).with().returns('repo_url')
      @strategy.stubs(:configuration).with().returns(:repository => 'repo_url')
      
      @strategy.repository_url_changed?.should be(false)
    end
    
    should "know that the repository URL has changed" do
      @strategy.stubs(:repository_url).with().returns('new_repo_url')
      @strategy.stubs(:configuration).with().returns(:repository => 'old_repo_url')
      
      @strategy.repository_url_changed?.should be(true)
    end
    
    should "be able to remove the local cache" do
      @strategy.stubs(:logger).with().returns(stub(:trace))
      @strategy.stubs(:local_cache_path).with().returns('local_cache_path')
      FileUtils.expects(:rm_rf).with('local_cache_path')
      
      @strategy.remove_local_cache
    end
    
    should "remove the local cache if the repository URL has changed" do
      @strategy.stubs(:repository_url_changed?).with().returns(true)
      @strategy.expects(:remove_local_cache).with()
      
      @strategy.remove_cache_if_repository_url_changed
    end
    
    should "not remove the local cache if the repository URL has not changed" do
      @strategy.stubs(:repository_url_changed?).with().returns(false)
      @strategy.expects(:remove_local_cache).with().never
      
      @strategy.remove_cache_if_repository_url_changed
    end
    
    should "know the default SSH port" do
      @strategy.stubs(:ssh_options).with().returns({})
      server = stub(:port => nil)
      @strategy.ssh_port(server).should == 22
    end
    
    should "be able to override the default SSH port" do
      @strategy.stubs(:ssh_options).with().returns({:port => 95})
      server = stub(:port => nil)
      @strategy.ssh_port(server).should == 95
    end

    should "be able to override the default SSH port for each server" do
      @strategy.stubs(:ssh_options).with().returns({:port => 95})
      server = stub(:port => 123)
      @strategy.ssh_port(server).should == 123
    end

    should "know the default repository cache" do
      @strategy.repository_cache.should == 'cached-copy'
    end
    
    should "be able to override the default repository cache" do
      @strategy.stubs(:configuration).with().returns(:repository_cache => 'other_cache')
      @strategy.repository_cache.should == 'other_cache'
    end
    
    should "know the repository cache path" do
      @strategy.stubs(:shared_path).with().returns('shared_path')
      @strategy.stubs(:repository_cache).with().returns('cache_path')
      
      File.expects(:join).with('shared_path', 'cache_path').returns('path')
      @strategy.repository_cache_path.should == 'path'
    end
    
    should "be able to determine the hostname for the rsync command" do
      server = stub(:host => 'host.com')
      @strategy.rsync_host(server).should == 'host.com'
    end
    
    should "be able to determine the hostname for the rsync command when a user is configured" do
      @strategy.stubs(:configuration).with().returns(:user => 'foobar')
      server = stub(:host => 'host.com')
      
      @strategy.rsync_host(server).should == 'foobar@host.com'
    end
    
    should "know that the local cache exists" do
      @strategy.stubs(:local_cache_path).with().returns('path')
      File.stubs(:exist?).with('path').returns(true)
      
      @strategy.local_cache_exists?.should be(true)
    end
    
    should "know that the local cache does not exist" do
      @strategy.stubs(:local_cache_path).with().returns('path')
      File.stubs(:exist?).with('path').returns(false)
      
      @strategy.local_cache_exists?.should be(false)
    end
    
    should "know that the local cache is not valid if it does not exist" do
      @strategy.stubs(:local_cache_exists?).with().returns(false)
      @strategy.local_cache_valid?.should be(false)
    end
    
    should "know that the local cache is not valid if it's not a directory" do
      @strategy.stubs(:local_cache_path).with().returns('path')
      @strategy.stubs(:local_cache_exists?).with().returns(true)
      
      File.stubs(:directory?).with('path').returns(false)
      @strategy.local_cache_valid?.should be(false)
    end
    
    should "know that the local cache is valid" do
      @strategy.stubs(:local_cache_path).with().returns('path')
      @strategy.stubs(:local_cache_exists?).with().returns(true)
      
      File.stubs(:directory?).with('path').returns(true)
      @strategy.local_cache_valid?.should be(true)
    end
    
    should "know the SCM command when the local cache is valid" do
      source = mock() {|s| s.expects(:sync).with('revision', 'path').returns('scm_command') }
      
      @strategy.stubs(:local_cache_valid?).with().returns(true)
      @strategy.stubs(:local_cache_path).with().returns('path')
      @strategy.stubs(:revision).with().returns('revision')
      @strategy.stubs(:source).with().returns(source)
      
      @strategy.send(:command).should == 'scm_command'
    end
    
    should "know the SCM command when the local cache does not exist" do
      source = mock() {|s| s.expects(:checkout).with('revision', 'path').returns('scm_command') }
      
      @strategy.stubs(:local_cache_valid?).with().returns(false)
      @strategy.stubs(:local_cache_exists?).with().returns(false)
      @strategy.stubs(:local_cache_path).with().returns('path')
      @strategy.stubs(:revision).with().returns('revision')
      @strategy.stubs(:source).with().returns(source)
      
      @strategy.send(:command).should == 'mkdir -p path && scm_command'
    end
    
    should "raise an exception when the local cache is invalid" do
      @strategy.stubs(:local_cache_valid?).with().returns(false)
      @strategy.stubs(:local_cache_exists?).with().returns(true)
  
      lambda {
        @strategy.send(:command) 
      }.should raise_error(Capistrano::Deploy::Strategy::RsyncWithRemoteCache::InvalidCacheError)
    end
    
    should "be able to tag the local cache" do
      local_cache_path = Dir.tmpdir
      @strategy.stubs(:revision).with().returns('1')
      @strategy.stubs(:local_cache_path).with().returns(local_cache_path)
      
      @strategy.mark_local_cache
      
      File.read(File.join(local_cache_path, 'REVISION')).should == '1'
    end
    
    should "be able to update the local cache" do
      @strategy.stubs(:command).with().returns('scm_command')
      @strategy.expects(:system).with('scm_command')
      @strategy.expects(:mark_local_cache).with()
      
      @strategy.update_local_cache
    end
    
    should "be able to run the rsync command on a server" do
      server = stub()
      
      @strategy.stubs(:rsync_host).with(server).returns('rsync_host')
      
      @strategy.stubs(
        :rsync_options         => 'rsync_options', 
        :ssh_port              => 'ssh_port',
        :local_cache_path      => 'local_cache_path',
        :repository_cache_path => 'repository_cache_path'
      )
      
      expected = "rsync rsync_options --rsh='ssh -p ssh_port' local_cache_path/ rsync_host:repository_cache_path/"
      
      @strategy.rsync_command_for(server).should == expected
    end
    
    should "be able to run the rsync command through a gateway" do
      server = stub()

      @strategy.stubs(:rsync_host).with(server).returns('rsync_host')
      @strategy.configuration.stubs(:[]).with(:gateway).returns('ssh_gateway')

      @strategy.stubs(
        :rsync_options         => 'rsync_options',
        :ssh_port              => 'ssh_port',
        :local_cache_path      => 'local_cache_path',
        :repository_cache_path => 'repository_cache_path'
      )

      expected = "rsync rsync_options --rsh='ssh -p ssh_port -o \"ProxyCommand ssh ssh_gateway nc -w300 %h %p\"' local_cache_path/ rsync_host:repository_cache_path/"

      @strategy.rsync_command_for(server).should == expected
    end

    should "be able to update the remote cache" do
      server_1, server_2 = [stub(), stub()]
      @strategy.stubs(:find_servers).with(:except => {:no_release => true}).returns([server_1, server_2])
      
      @strategy.stubs(:rsync_command_for).with(server_1).returns('server_1_rsync_command')
      @strategy.stubs(:rsync_command_for).with(server_2).returns('server_2_rsync_command')
      
      @strategy.expects(:system).with('server_1_rsync_command').returns(true)
      @strategy.expects(:system).with('server_2_rsync_command').returns(true)
      
      @strategy.update_remote_cache
    end
    
    should "notice failure to update teh remote cache" do
      server_1, server_2 = [stub(), stub()]
      @strategy.stubs(:find_servers).with(:except => {:no_release => true}).returns([server_1, server_2])

      @strategy.stubs(:rsync_command_for).with(server_1).returns('server_1_rsync_command')
      @strategy.stubs(:rsync_command_for).with(server_2).returns('server_2_rsync_command')

      @strategy.expects(:system).with('server_1_rsync_command').returns(false)
      @strategy.expects(:system).with('server_2_rsync_command').never
 
      lambda { @strategy.update_remote_cache }.should raise_error
    end

    should "be able copy the remote cache into place" do
      @strategy.stubs(
        :repository_cache_path => 'repository_cache_path',
        :configuration         => {:release_path => 'release_path'}
      )
      
      command = "rsync -a --delete repository_cache_path/ release_path/"
      @strategy.expects(:run).with(command)
      
      @strategy.copy_remote_cache
    end
    
    should "be able to deploy" do
      @strategy.expects(:update_local_cache).with()
      @strategy.expects(:update_remote_cache).with()
      @strategy.expects(:copy_remote_cache).with()
      
      @strategy.deploy!
    end
    
  end
  
end
