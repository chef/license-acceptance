require "license_acceptance/strategy/base"

module LicenseAcceptance
  module Strategy

    # Look for acceptance values in the ARGV
    class Argument < Base

      FLAG = "--chef-license".freeze

      attr_reader :argv

      def initialize(argv)
        @argv = argv
      end

      def accepted?
        look_for_value(ACCEPT)
      end

      def silent?
        look_for_value(ACCEPT_SILENT)
      end

      def no_persist?
        look_for_value(ACCEPT_NO_PERSIST)
      end

      def value?
        argv.any? { |s| s == FLAG || s.start_with?("#{FLAG}=") }
      end

      private

      def look_for_value(sought)
        if argv.include?("#{FLAG}=#{sought}")
          return true
        end

        i = argv.index(FLAG)
        unless i.nil?
          val = argv[i + 1]
          if !val.nil? && val.downcase == sought
            return true
          end
        end
        false
      end
    end
  end
end
