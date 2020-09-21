
lib = File.expand_path("lib", __dir__)
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

  spec.required_ruby_version = ">= 2.4"

  spec.add_dependency "pastel", "~> 0.7"
  spec.add_dependency "tomlrb", "~> 1.2"
  spec.add_dependency "tty-box", "~> 0.6" # 0.6 resolves ruby 2.7 warnings
  spec.add_dependency "tty-prompt", "~> 0.20" # 0.20 resolves ruby 2.7 warnings
end
