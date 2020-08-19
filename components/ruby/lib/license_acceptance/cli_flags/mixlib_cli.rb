begin
  require "mixlib/cli"
rescue
  raise "Must have mixlib-cli gem installed to use this mixin"
end

module LicenseAcceptance
  module CLIFlags

    module MixlibCLI

      def self.included(klass)
        klass.option :chef_license,
          long: "--chef-license ACCEPTANCE",
          description: "Accept the license for this product and any contained products",
          in: %w{accept accept-no-persist accept-silent},
          required: false
      end

    end

  end
end
