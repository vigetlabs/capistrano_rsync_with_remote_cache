require 'rake/testtask'
require 'bundler'
require 'gem_publisher'

Bundler::GemHelper.install_tasks

Rake::TestTask.new do |t|
  t.libs << 'test'
  t.test_files = FileList["test/**/*_test.rb"]
  t.verbose = true
end

desc "Publish gem to gemfury"
task :publish_gem => :build do |t|
  gem = GemPublisher.publish_if_updated('capistrano_rsync_with_remote_cache.gemspec', :gemfury)
  puts "Published #{gem}" if gem
end

task :default => :test
