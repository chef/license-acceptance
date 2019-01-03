begin
  require 'mixlib/cli'
rescue => exception
  raise "Must have mixlib-cli gem installed to use this mixin"
end

module LicenseAcceptance
  module CLIFlags

    module MixlibCLI

      def self.included(klass)
        klass.option :accept_license,
          long: "--accept-license",
          description: "Accept the license for this product and any contained products",
          boolean: true
      end

    end

  end
end
