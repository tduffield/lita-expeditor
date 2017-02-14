$:.unshift(File.dirname(__FILE__) + "/lib")
require "expeditor/version"

Gem::Specification.new do |spec|
  spec.name          = "lita-expeditor"
  spec.version       = Expeditor::VERSION
  spec.authors       = ["Tom Duffield"]
  spec.email         = ["tom@chef.io"]
  spec.description   = "Lita plugin to expidite development at Chef Software, Inc. for projects managed through Github"
  spec.summary       = spec.description
  spec.homepage      = "https://github.com/chef/lita-expeditor"
  spec.license       = "Apache-2.0"
  spec.metadata      = { "lita_plugin_type" => "handler" }

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "lita", ">= 4.7"
  spec.add_runtime_dependency "tomlrb"
  spec.add_runtime_dependency "octokit"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "pry-byebug"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rack-test"
  spec.add_development_dependency "rspec", ">= 3.0.0"
  spec.add_development_dependency "simplecov"
  spec.add_development_dependency "coveralls"
end
