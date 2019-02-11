require "license_acceptance/product_relationship"
require "license_acceptance/file_acceptance"
require "license_acceptance/arg_acceptance"
require "license_acceptance/prompt_acceptance"

module LicenseAcceptance
  class Acceptor
    # TODO let them pass in whether running this as a library tool or a workstation tool - maybe
    # an environment variable?
    def self.check_and_persist(product_name, version)
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
      # TODO change this to take some kind of passed in output class instead of STDOUT
      # TODO what if they are not running in a TTY?
      elsif PromptAcceptance.request(missing_licenses, STDOUT) do
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
