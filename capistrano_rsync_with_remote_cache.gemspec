# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{capistrano_rsync_with_remote_cache}
  s.version = "2.3.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Mark Cornick"]
  s.date = %q{2009-05-18}
  s.description = %q{A deployment strategy for Capistrano 2.0 which combines rsync with a remote cache, allowing fast deployments from SCM servers behind firewalls.}
  s.email = %q{mark@viget.com}
  s.extra_rdoc_files = [
    "LICENSE",
    "README.md"
  ]
  s.files = [
    "LICENSE",
    "README.md",
    "Rakefile",
    "VERSION.yml",
    "lib/capistrano/recipes/deploy/strategy/rsync_with_remote_cache.rb",
    "test/capistrano_rsync_with_remote_cache_test.rb",
    "test/test_helper.rb"
  ]
  s.has_rdoc = true
  s.homepage = %q{http://github.com/vigetlabs/capistrano_rsync_with_remote_cache}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{viget}
  s.rubygems_version = %q{1.3.2}
  s.summary = %q{rsync_with_remote_cache strategy for Capistrano}
  s.test_files = [
    "test/capistrano_rsync_with_remote_cache_test.rb",
    "test/test_helper.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<capistrano>, [">= 2.0"])
    else
      s.add_dependency(%q<capistrano>, [">= 2.0"])
    end
  else
    s.add_dependency(%q<capistrano>, [">= 2.0"])
  end
end
