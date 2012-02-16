# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{capistrano_rsync_with_remote_cache}
  s.version = "2.4.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Patrick Reagan", "Mark Cornick"]
  s.date = %q{2012-02-16}
  s.email = %q{patrick.reagan@viget.com}
  s.extra_rdoc_files = ["README.rdoc"]
  s.files = ["README.rdoc", "Rakefile", "lib/capistrano", "lib/capistrano/recipes", "lib/capistrano/recipes/deploy", "lib/capistrano/recipes/deploy/strategy", "lib/capistrano/recipes/deploy/strategy/rsync_with_remote_cache.rb", "test/capistrano_rsync_with_remote_cache_test.rb"]
  s.homepage = %q{http://www.viget.com/extend/}
  s.rdoc_options = ["--main", "README.rdoc"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.6}
  s.summary = %q{A deployment strategy for Capistrano 2.0 which combines rsync with a remote cache, allowing fast deployments from SCM servers behind firewalls.}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<capistrano>, [">= 2.1.0"])
      s.add_runtime_dependency(%q<rake>, [">= 0"])
      s.add_runtime_dependency(%q<mocha>, [">= 0"])
      s.add_runtime_dependency(%q<shoulda>, [">= 0"])
      s.add_runtime_dependency(%q<jnunemaker-matchy>, [">= 0"])
    else
      s.add_dependency(%q<capistrano>, [">= 2.1.0"])
      s.add_dependency(%q<rake>, [">= 0"])
      s.add_dependency(%q<mocha>, [">= 0"])
      s.add_dependency(%q<shoulda>, [">= 0"])
      s.add_dependency(%q<jnunemaker-matchy>, [">= 0"])
    end
  else
    s.add_dependency(%q<capistrano>, [">= 2.1.0"])
    s.add_dependency(%q<rake>, [">= 0"])
    s.add_dependency(%q<mocha>, [">= 0"])
    s.add_dependency(%q<shoulda>, [">= 0"])
    s.add_dependency(%q<jnunemaker-matchy>, [">= 0"])
  end
end
