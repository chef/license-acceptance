require "license_acceptance/product_relationship"
require "license_acceptance/file_acceptance"
require "license_acceptance/arg_acceptance"
require "license_acceptance/prompt_acceptance"

module LicenseAcceptance
  class Acceptor

    # For applications that just need simple logic to handle a failed license
    # acceptance flow we include this small wrapper. Apps with more complex logic
    # (like logging to a  logging engine) should call the non-bang version and
    # handle the exception.
    def self.check_and_persist!(product_name, version, output=$stdout)
      check_and_persist(product_name, version, output)
    rescue LicenseNotAcceptedError
      output.puts "#{product_name} cannot execute without accepting the license"
      exit 172
    end

    def self.check_and_persist(product_name, version, output=STDOUT)
      # flag for test environments to set - not for use by consumers
      return true if ENV['ACCEPT_CHEF_LICENSE_NO_PERSIST'] == 'true'

      product_relationship = ProductRelationship.lookup(product_name, version)
      missing_licenses = FileAcceptance.check(product_relationship)

      # They have already accepted all licenses and stored their acceptance in the persistent files
      return true if missing_licenses.empty?

      # They passed the --accept-license flag on the command line
      if ArgAcceptance.check(ARGV) do
          FileAcceptance.persist(product_relationship, missing_licenses)
        end
        return true
      # TODO what if they have accepted the license for chef, but a new child gets added? Seems like we need to ask
      # for the new children
      # TODO what if they are not running in a TTY?
      elsif PromptAcceptance.request(missing_licenses, output) do
          FileAcceptance.persist(product_relationship, missing_licenses)
        end
        return true
      else
        raise LicenseNotAcceptedError.new(missing_licenses)
      end
    end

  end

  class LicenseNotAcceptedError < RuntimeError
    def initialize(missing_licenses)
      msg = "Missing licenses for the following:\n* " + missing_licenses.join("\n* ")
      super(msg)
    end
  end

end
