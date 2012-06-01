require 'rubygems'
require 'rake/gempackagetask'
require 'rake/testtask'

spec = Gem::Specification.new do |s|
  s.name             = 'capistrano_rsync_with_remote_cache'
  s.version          = '2.4.0.1'
  s.has_rdoc         = true
  s.extra_rdoc_files = %w(README.rdoc)
  s.rdoc_options     = %w(--main README.rdoc)
  s.summary          = "A deployment strategy for Capistrano 2.0 which combines rsync with a remote cache, allowing fast deployments from SCM servers behind firewalls."
  s.authors          = ['Patrick Reagan', 'Mark Cornick']
  s.email            = 'patrick.reagan@viget.com'
  s.homepage         = 'http://www.viget.com/extend/'
  s.files            = %w(README.rdoc Rakefile) + Dir.glob("{lib,test}/**/*")

  s.add_dependency('capistrano', '>=2.1.0')
end

Rake::GemPackageTask.new(spec) do |pkg|
  pkg.gem_spec = spec
end

Rake::TestTask.new do |t|
  t.libs << 'test'
  t.test_files = FileList["test/**/*_test.rb"]
  t.verbose = true
end

task :default => :test
