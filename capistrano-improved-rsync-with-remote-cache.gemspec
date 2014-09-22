# -*- encoding: utf-8 -*-

Gem::Specification.new do |gem|
  gem.name          = "capistrano-improved-rsync-with-remote-cache"
  gem.version       = "1.1.2"
  gem.authors       = ["Carlos Buenosvinos"]
  gem.email         = ["carlos.buenosvinos@gmail.com"]
  gem.homepage      = "https://github.com/carlosbuenosvinos/capistrano_improved_rsync_with_remote_cache"
  gem.summary       = %q{Improved version of rsync-with-remote-cache deployment strategy.}
  gem.description   = %q{Improved version of rsync-with-remote-cache deployment strategy.}

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency('capistrano', '>=2.4.0')
  gem.add_dependency('parallel', '>=0.0.0')
end
