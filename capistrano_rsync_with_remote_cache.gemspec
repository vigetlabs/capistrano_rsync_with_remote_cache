# -*- encoding: utf-8 -*-
Gem::Specification.new do |s|
  s.name = %q{capistrano_rsync_with_remote_cache}
  s.version = "2.4.0govuk1"

  s.authors = ["Patrick Reagan", "Mark Cornick"]
  s.date = %q{2012-02-16}
  s.email = %q{patrick.reagan@viget.com}
  s.summary = %q{A deployment strategy for Capistrano 2.0 which combines rsync with a remote cache, allowing fast deployments from SCM servers behind firewalls.}
  s.homepage = %q{http://www.viget.com/extend/}

  s.files            = `git ls-files`.split($\)
  s.test_files       = s.files.grep(%r{^(test|spec|features)/})
  s.require_paths    = ["lib"]
  s.extra_rdoc_files = ["README.rdoc"]
  s.rdoc_options     = ["--main", "README.rdoc"]

  s.add_runtime_dependency 'capistrano', '>= 2.1.0'

  s.add_development_dependency 'rake'
  s.add_development_dependency 'mocha'
  s.add_development_dependency 'shoulda'
  s.add_development_dependency 'jnunemaker-matchy'

  s.add_development_dependency 'gem_publisher', '~> 1.1.1'
  s.add_development_dependency 'gemfury'
end
