require File.expand_path("../lib/env_vars", __FILE__)

Gem::Specification.new do |spec|
  spec.name          = "env_vars"
  spec.version       = Env::Vars::VERSION
  spec.authors       = ["Nando Vieira"]
  spec.email         = ["fnando.vieira@gmail.com"]

  spec.summary       = "Access environment variables. Also includes presence validation, type coercion and default values."
  spec.description   = spec.summary
  spec.homepage      = "https://github.com/fnando/env_vars"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject {|f| f.match(%r{^(test|spec|features)/}) }
  spec.executables   = spec.files.grep(%r{^exe/}) {|f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest"
  spec.add_development_dependency "minitest-utils"
end
