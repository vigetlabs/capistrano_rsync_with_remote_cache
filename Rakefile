require 'rubygems'
require 'rake/gempackagetask'
require 'rake/testtask'

require File.join(File.dirname(__FILE__), %w(lib capistrano_rsync_with_remote_cache version))

spec = Gem::Specification.new do |s|
  s.name             = 'capistrano_rsync_with_remote_cache'
  s.version          = CapistranoRsyncWithRemoteCache::Version.to_s
  s.has_rdoc         = true
  s.extra_rdoc_files = %w(README.md)
  # s.rdoc_options     = %w(--main README.rdoc)
  s.summary          = "A deployment strategy for Capistrano 2.0 which combines rsync with a remote cache, allowing fast deployments from SCM servers behind firewalls."
  s.author           = 'Mark Cornick'
  s.email            = 'developers@viget.com'
  s.homepage         = 'http://www.viget.com/extend/'
  s.files            = %w(README.md Rakefile) + Dir.glob("{lib,test}/**/*")
  # s.executables    = ['capistrano_rsync_with_remote_cache']
  
  # s.add_dependency('gem_name', '~> 0.0.1')
end

Rake::GemPackageTask.new(spec) do |pkg|
  pkg.gem_spec = spec
end

Rake::TestTask.new do |t|
  t.libs << 'test'
  t.test_files = FileList["test/**/*_test.rb"]
  t.verbose = true
end

begin
  require 'rcov/rcovtask'

  exclude_paths  = %w(/Library/Ruby /usr/lib/ruby)
  exclude_paths += Array(Gem.path)

  options = ['--text-report'] + exclude_paths.map {|p| "-x '#{p}'" }

  Rcov::RcovTask.new(:coverage) do |t|
    t.libs       = ['test']
    t.test_files = FileList["test/**/*_test.rb"]
    t.verbose    = true
    t.rcov_opts  = options
  end
  
  task :default => :coverage
  
rescue LoadError
  warn "\n**** Install rcov (gem install rcov) to get coverage stats ****\n"
  task :default => :test
end
