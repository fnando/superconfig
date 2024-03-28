# frozen_string_literal: true

require_relative "lib/superconfig"

Gem::Specification.new do |spec|
  spec.name          = "superconfig"
  spec.version       = SuperConfig::VERSION
  spec.authors       = ["Nando Vieira"]
  spec.email         = ["me@fnando.com"]
  spec.required_ruby_version = Gem::Requirement.new(">= 3.1.0")
  spec.metadata = {"rubygems_mfa_required" => "true"}

  spec.summary       = "Access environment variables. Also includes presence " \
                       "validation, type coercion and default values."
  spec.description   = spec.summary
  spec.homepage      = "https://github.com/fnando/superconfig"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`
                       .split("\x0")
                       .reject {|f| f.match(%r{^(test|spec|features)/}) }
  spec.executables   = spec.files.grep(%r{^exe/}) {|f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "minitest"
  spec.add_development_dependency "minitest-utils"
  spec.add_development_dependency "pry-meta"
  spec.add_development_dependency "rails"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rubocop"
  spec.add_development_dependency "rubocop-fnando"
  spec.add_development_dependency "simplecov"
end
