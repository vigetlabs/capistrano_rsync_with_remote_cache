require 'rubygems'
Gem::manage_gems
require 'rake/gempackagetask'

spec = Gem::Specification.new do |s|
  s.name = 'capistrano_rsync_with_remote_cache'
  s.version = '2.2'
  s.author = 'Mark Cornick'
  s.email = 'mark@viget.com'
  s.homepage = 'http://trac.extendviget.com/lab/wiki/CapistranoRsyncWithRemoteCache'
  s.platform = Gem::Platform::RUBY
  s.summary = 'A deployment strategy for Capistrano 2.0 which combines rsync with a remote cache, allowing fast deployments from SCM servers behind firewalls.'
  s.files = ['lib/capistrano/recipes/deploy/strategy/rsync_with_remote_cache.rb']
  s.require_path = 'lib'
  s.has_rdoc = true
  s.extra_rdoc_files = ['README']
  s.add_dependency("capistrano", ">= 2.0")
end

Rake::GemPackageTask.new(spec) do |p|
  p.need_tar = false
end
