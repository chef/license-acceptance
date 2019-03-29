
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "license_acceptance/version"

Gem::Specification.new do |spec|
  spec.name          = "license-acceptance"
  spec.version       = LicenseAcceptance::VERSION
  spec.authors       = ["tyler-ball"]
  spec.email         = ["tball@chef.io"]

  spec.summary       = %q{License acceptance flow for Chef Ruby products}
  spec.description   = %q{License acceptance flow for Chef Ruby products}
  spec.homepage      = "https://chef.io"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "http://mygemserver.com"

    # spec.metadata["homepage_uri"] = spec.homepage
    # spec.metadata["source_code_uri"] = "TODO: Put your gem's public repo URL here."
    # spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files         = %w{Gemfile Gemfile.lock Rakefile} + Dir.glob("{lib,spec,config}/**/*")

  spec.bindir        = "bin"
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'pastel', ">= 0.7"
  spec.add_dependency 'tomlrb', "~> 1.2"
  spec.add_dependency 'tty-box', ">= 0.3"
  spec.add_dependency 'tty-platform', ">= 0.2"
  spec.add_dependency 'tty-prompt', ">= 0.18"

  spec.add_development_dependency "bundler", ">= 1.17"
  spec.add_development_dependency "rake", ">= 10.0"
  spec.add_development_dependency "rspec", ">= 3.0"
  spec.add_development_dependency "pry", ">= 0.12"
  spec.add_development_dependency "pry-byebug", ">= 3.6"
  spec.add_development_dependency "pry-stack_explorer", ">= 0.4"
  spec.add_development_dependency "mixlib-cli", ">= 1.7"
  spec.add_development_dependency "thor", ">= 0.20"
  spec.add_development_dependency "climate_control", ">= 0.2"
end
