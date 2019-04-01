begin
  require 'thor'
rescue => exception
  raise "Must have thor gem installed to use this mixin"
end

module LicenseAcceptance
  module CLIFlags

    module Thor

      def self.included(klass)
        klass.class_option :accept_license,
          type: :string,
          banner: '',
          desc: 'Accept the license for this product and any contained products'
      end

    end

  end
end
