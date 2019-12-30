
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "license_acceptance/version"

Gem::Specification.new do |spec|
  spec.name          = "license-acceptance"
  spec.version       = LicenseAcceptance::VERSION
  spec.authors       = ["tyler-ball"]
  spec.email         = ["tball@chef.io"]

  spec.summary       = %q{Chef End User License Agreement Acceptance}
  spec.description   = %q{Chef End User License Agreement Acceptance for Ruby products}
  spec.homepage      = "https://github.com/chef/license-acceptance/"
  spec.license       = "Apache-2.0"

  spec.files         = %w{Gemfile LICENSE} + Dir.glob("{lib,config}/**/*")

  spec.require_paths = ["lib"]

  # We must support Ruby 2.3 because TK 1.x still uses that. When that is EOL
  # we can move to Ruby 2.4
  spec.required_ruby_version = ">= 2.3"

  spec.add_dependency "pastel", "~> 0.7"
  spec.add_dependency "tomlrb", "~> 1.2"
  spec.add_dependency "tty-box", "~> 0.3"
  spec.add_dependency "tty-prompt", "~> 0.18"

  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "pry", "~> 0.12"
  spec.add_development_dependency "pry-byebug", "~> 3.6"
  spec.add_development_dependency "pry-stack_explorer", "~> 0.4"
  spec.add_development_dependency "mixlib-cli", "~> 1.7"
  spec.add_development_dependency "thor", "~> 0.20"
  spec.add_development_dependency "climate_control", "~> 0.2"
end
