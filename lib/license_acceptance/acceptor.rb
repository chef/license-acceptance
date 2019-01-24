require "license_acceptance/product_relationship"
require "license_acceptance/file_acceptance"
require "license_acceptance/arg_acceptance"
require "license_acceptance/prompt_acceptance"

module LicenseAcceptance
  class Acceptor
    # TODO let them pass in whether running this as a library tool or a workstation tool - maybe
    # an environment variable?
    def self.check_and_persist(product_name, version)
      product_relationship = ProductRelationship.lookup(product_name, version)
      missing_licenses = FileAcceptance.check(product_relationship)
      # They have already accepted all licenses and stored their acceptance in the persistent files
      if missing_licenses.empty?
        return true
      # They passed the --accept-license flag on the command line
      elsif answer = ArgAcceptance.check(ARGV) do
          FileAcceptance.persist(product_relationship, missing_licenses)
        end
        return answer
      # TODO what if they have accepted the license for chef, but a new child gets added? Seems like we need to ask
      # for the new children
      # They typed 'yes' to accept the license(s) on the command line
      # TODO change this to take some kind of passed in output class
      elsif answer = PromptAcceptance.request(missing_licenses, STDOUT) do
          FileAcceptance.persist(product_relationship, missing_licenses)
        end
        return answer
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
