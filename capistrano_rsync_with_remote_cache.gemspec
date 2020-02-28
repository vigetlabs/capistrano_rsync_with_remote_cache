# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name             = 'capistrano_rsync_with_remote_cache'
  spec.version          = '2.4.0'
  spec.authors          = ['Patrick Reagan', 'Mark Cornick']
  spec.email            = ['patrick.reagan@viget.com']

  spec.has_rdoc         = true
  spec.extra_rdoc_files = %w(README.rdoc)
  spec.rdoc_options     = %w(--main README.rdoc)
  spec.summary          = "A deployment strategy for Capistrano 2.0 which combines rsync with a remote cache, allowing fast deployments from SCM servers behind firewalls."
  spec.description      = spec.summary
  spec.homepage         = 'https://github.com/vigetlabs/capistrano_rsync_with_remote_cache'
  spec.files            = %w(README.rdoc Rakefile) + Dir.glob("{lib,spec}/**/*")

  spec.add_dependency  'capistrano', '~> 2.0'

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rspec", "~> 3.1.0"
  spec.add_development_dependency "rake", "~> 12.3"
end
