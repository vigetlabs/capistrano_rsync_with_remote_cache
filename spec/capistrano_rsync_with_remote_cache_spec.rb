require 'rubygems'
require 'bundler/setup'

require 'rspec'
require 'tmpdir'

require 'capistrano/recipes/deploy/strategy/rsync_with_remote_cache'

RSpec.describe Capistrano::Deploy::Strategy::RsyncWithRemoteCache do

  describe "#rsync_options" do
    it "has a default value" do
      expect(subject.rsync_options).to eq('-az --delete')
    end

    it "allows a user-specified value" do
      expect(subject).to receive(:configuration).with(no_args).and_return(:rsync_options => 'new_opts')
      expect(subject.rsync_options).to eq('new_opts')
    end
  end

  describe "#local_cache" do
    it "has a default value" do
      expect(subject.local_cache).to eq('.rsync_cache')
    end

    it "allows a user-specified value" do
      expect(subject).to receive(:configuration).with(no_args).and_return(:local_cache => 'cache')
      expect(subject.local_cache).to eq('cache')
    end
  end

  describe "#local_cache_path" do
    it "is generated from the full path to the cache" do
      expect(subject).to receive(:local_cache).with(no_args).and_return('cache_dir')
      expect(File).to receive(:expand_path).with('cache_dir').and_return('local_cache_path')

      expect(subject.local_cache_path).to eq('local_cache_path')
    end
  end

  describe "#repository_url" do
    before { expect(subject).to receive(:local_cache_path).with(no_args).and_return('cache_path') }

    it "knows the value for a Subversion repository" do
      expect(subject).to receive(:configuration).with(no_args).and_return(:scm => :subversion)
      expect(subject).to receive(:`).with("cd cache_path && svn info . | sed -n \'s/URL: //p\'").and_return("svn_url\n")
      expect(subject.repository_url).to eq('svn_url')
    end

    it "knows the value for a Git repository" do
      expect(subject).to receive(:configuration).with(no_args).and_return(:scm => :git)
      expect(subject).to receive(:`).with("cd cache_path && git config remote.origin.url").and_return("git_url\n")
      expect(subject.repository_url).to eq('git_url')
    end

    it "knows the value for a Mercurial repository" do
      expect(subject).to receive(:configuration).with(no_args).and_return(:scm => :mercurial)
      expect(subject).to receive(:`).with("cd cache_path && hg showconfig paths.default").and_return("hg_url\n")
      expect(subject.repository_url).to eq('hg_url')
    end

    it "knows the value for a bzr repository" do
      expect(subject).to receive(:configuration).with(no_args).and_return(:scm => :bzr)
      expect(subject).to receive(:`).with("cd cache_path && bzr info | grep parent | sed \'s/^.*parent branch: //\'").and_return("bzr_url\n")
      expect(subject.repository_url).to eq('bzr_url')
    end
  end

  describe "#url_changed?" do
    it "is false if it has not changed" do
      expect(subject).to receive(:repository_url).with(no_args).and_return('repo_url')
      expect(subject).to receive(:configuration).with(no_args).and_return(:repository => 'repo_url')

      expect(subject.repository_url_changed?).to be(false)
    end

    it "is true if it has changed" do
      expect(subject).to receive(:repository_url).with(no_args).and_return('new_repo_url')
      expect(subject).to receive(:configuration).with(no_args).and_return(:repository => 'old_repo_url')

      expect(subject.repository_url_changed?).to be(true)
    end
  end

  describe "#remove_local_cache" do
    it "removes the local directory" do
      expect(subject).to receive(:logger).with(no_args).and_return(double(:trace => nil))
      expect(subject).to receive(:local_cache_path).at_least(:once).with(no_args).and_return('local_cache_path')
      expect(FileUtils).to receive(:rm_rf).with('local_cache_path')

      subject.remove_local_cache
    end
  end

  describe "#remove_cache_if_repository_url_changed" do
    it "removes the local cache if the repository URL has changed" do
      expect(subject).to receive(:repository_url_changed?).with(no_args).and_return(true)
      expect(subject).to receive(:remove_local_cache).with(no_args)

      subject.remove_cache_if_repository_url_changed
    end

    it "does not remove the local cache if the repository URL has not changed" do
      expect(subject).to receive(:repository_url_changed?).with(no_args).and_return(false)
      expect(subject).to receive(:remove_local_cache).never

      subject.remove_cache_if_repository_url_changed
    end
  end


  describe "#ssh_port" do
    it "knows the default value" do
      server = double(:port => nil)

      allow(subject).to receive(:ssh_options).with(no_args).and_return({})
      expect(subject.ssh_port(server)).to eq(22)
    end

    it "can be globally overridden" do
      server = double(:port => nil)

      allow(subject).to receive(:ssh_options).with(no_args).and_return({:port => 95})
      expect(subject.ssh_port(server)).to eq(95)
    end

    it "can be set on a per-server basis" do
      server = double(:port => 123)

      allow(subject).to receive(:ssh_options).with(no_args).and_return({:port => 95})
      expect(subject.ssh_port(server)).to eq(123)
    end
  end

  describe "#repository_cache" do
    it "has a default value" do
      expect(subject.repository_cache).to eq('cached-copy')
    end

    it "can be overridden" do
      allow(subject).to receive(:configuration).with(no_args).and_return(:repository_cache => 'other_cache')
      expect(subject.repository_cache).to eq('other_cache')
    end
  end

  describe "#repository_cache_path" do
    it "is generated from the full path to the cache" do
      allow(subject).to receive(:shared_path).with(no_args).and_return('shared_path')
      allow(subject).to receive(:repository_cache).with(no_args).and_return('cache_path')

      allow(File).to receive(:join).with('shared_path', 'cache_path').and_return('path')

      expect(subject.repository_cache_path).to eq('path')
    end
  end

  describe "#rsync_host" do
    let(:server) { double(:host => 'host.com') }
    it "is taken from the server's host attribute by default" do
      expect(subject.rsync_host(server)).to eq('host.com')
    end

    it "can be overridden" do
      allow(subject).to receive(:configuration).with(no_args).and_return(:user => 'foobar')

      expect(subject.rsync_host(server)).to eq('foobar@host.com')
    end
  end

  describe "#local_cache_exists?" do
    it "returns true when the directory exists" do
      allow(subject).to receive(:local_cache_path).with(no_args).and_return('path')
      allow(File).to receive(:exist?).with('path').and_return(true)

      expect(subject.local_cache_exists?).to be(true)
    end

    it "returns false when the directory does not exist" do
      allow(subject).to receive(:local_cache_path).with(no_args).and_return('path')
      allow(File).to receive(:exist?).with('path').and_return(false)

      expect(subject.local_cache_exists?).to be(false)
    end
  end

  describe "#local_cache_valid?" do
    it "is false if the cache directory does not exist" do
      allow(subject).to receive(:local_cache_exists?).with(no_args).and_return(false)
      expect(subject.local_cache_valid?).to be(false)
    end

    it "is false if the cache path is not a directory" do
      allow(subject).to receive(:local_cache_path).with(no_args).and_return('path')
      allow(subject).to receive(:local_cache_exists?).with(no_args).and_return(true)

      allow(File).to receive(:directory?).with('path').and_return(false)

      expect(subject.local_cache_valid?).to be(false)
    end

    it "is true if the cache path exists and is a directory" do
      allow(subject).to receive(:local_cache_path).with(no_args).and_return('path')
      allow(subject).to receive(:local_cache_exists?).with(no_args).and_return(true)

      allow(File).to receive(:directory?).with('path').and_return(true)

      expect(subject.local_cache_valid?).to be(true)
    end
  end

  describe "#command" do
    let(:source) { double(:source) }

    before do
      allow(subject).to receive(:local_cache_path).with(no_args).and_return('path')
      allow(subject).to receive(:revision).with(no_args).and_return('revision')
      allow(subject).to receive(:source).with(no_args).and_return(source)

    end

    it "handles the case when the local cache exists" do
      allow(source).to receive(:sync).with('revision', 'path').and_return('scm_command')

      allow(subject).to receive(:local_cache_valid?).with(no_args).and_return(true)

      expect(subject.command).to eq('scm_command')
    end

    it "handles the case where the local cache does not exist" do
      allow(source).to receive(:checkout).with('revision', 'path').and_return('scm_command')

      allow(subject).to receive(:local_cache_valid?).with(no_args).and_return(false)
      allow(subject).to receive(:local_cache_exists?).with(no_args).and_return(false)

      expect(subject.command).to eq('mkdir -p path && scm_command')
    end

    it "raises an exception when the local cache is invalid" do
      allow(subject).to receive(:local_cache_valid?).with(no_args).and_return(false)
      allow(subject).to receive(:local_cache_exists?).with(no_args).and_return(true)

      expect { subject.command }.to raise_error(Capistrano::Deploy::Strategy::RsyncWithRemoteCache::InvalidCacheError)
    end
  end

  describe "#mark_local_cache" do
    let(:local_cache_path) { Dir.tmpdir }
    let(:revision_path)    { File.join(local_cache_path, 'REVISION') }

    before do
      allow(subject).to receive(:local_cache_path).with(no_args).and_return(local_cache_path)
    end

    it "creates a file with the current revision" do
      allow(subject).to receive(:revision).with(no_args).and_return('1')

      subject.mark_local_cache

      expect(File.read(revision_path)).to eq('1')
    end

    it "updates the revision file with the new revision" do
      File.open(revision_path, 'w') {|f| f << '1' }

      allow(subject).to receive(:revision).with(no_args).and_return('2')

      expect { subject.mark_local_cache }.to change { File.read(revision_path) }.from('1').to('2')
    end
  end

  describe "#update_local_cache" do
    it "marks the local cache after fetching the source" do
      allow(subject).to receive(:command).with(no_args).and_return('scm_command')
      expect(subject).to receive(:system).with('scm_command')
      expect(subject).to receive(:mark_local_cache).with(no_args)

      subject.update_local_cache
    end
  end

  describe "#rsync_command_for" do
    it "returns the correct rsync command based on the options" do
      server = double(:server)

      allow(subject).to receive(:rsync_host).with(server).and_return('rsync_host')

      allow(subject).to receive_messages({
        :rsync_options         => 'rsync_options',
        :ssh_port              => 'ssh_port',
        :local_cache_path      => 'local_cache_path',
        :repository_cache_path => 'repository_cache_path'
      })

      expected = "rsync rsync_options --rsh='ssh -p ssh_port' local_cache_path/ rsync_host:repository_cache_path/"

      expect(subject.rsync_command_for(server)).to eq(expected)
    end
  end

  describe "#update_remote_cache" do
    it "updates the cache on all applicable servers" do
      server_1, server_2 = [double(:server), double(:server)]

      allow(subject).to receive(:find_servers).with(:except => {:no_release => true}).and_return([server_1, server_2])

      allow(subject).to receive(:rsync_command_for).with(server_1).and_return('server_1_rsync_command')
      allow(subject).to receive(:rsync_command_for).with(server_2).and_return('server_2_rsync_command')

      expect(subject).to receive(:system).with('server_1_rsync_command')
      expect(subject).to receive(:system).with('server_2_rsync_command')

      subject.update_remote_cache
    end
  end

  describe "#copy_remote_cache" do
    it "runs the appropriate rsync command" do
      allow(subject).to receive_messages({
        :repository_cache_path => 'repository_cache_path',
        :configuration         => {:release_path => 'release_path'}
      })

      command = "rsync -a --delete repository_cache_path/ release_path/"
      expect(subject).to receive(:run).with(command)

      subject.copy_remote_cache
    end
  end

  describe "#deploy!" do
    it "deploys the code" do
      expect(subject).to receive(:update_local_cache).with(no_args)
      expect(subject).to receive(:update_remote_cache).with(no_args)
      expect(subject).to receive(:copy_remote_cache).with(no_args)

      subject.deploy!
    end

  end

end