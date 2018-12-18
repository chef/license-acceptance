require "license-acceptance/product_set"
require "license-acceptance/file_acceptance"
require "license-acceptance/arg_acceptance"
require "license-acceptance/prompt_acceptance"

module LicenseAcceptance
  class Acceptor
    # TODO let them pass in whether running this as a library tool or a workstation tool - maybe
    # an environment variable?
    def self.check_and_persist(product_name)
      product_set = ProductSet.lookup(product_name)
      missing_licenses = FileAcceptance.check(product_set)
      if missing_licenses.empty?
        # They have already accepted all licenses and stored their acceptance in the persistent files
        return true
      elsif ArgAcceptance.check(ARGV)
        # They passed the --accept-license flag on the command line
        FileAcceptance.persist(product_set, missing_licenses)
        return true
      # TODO what if they have accepted the license for chef, but a new child gets added? Seems like we need to ask
      # for the new children
      elsif PromptAcceptance.request(product_set, missing_licenses)
        # They typed 'yes' to accept the license(s) on the command line
        FileAcceptance.persist(product_set, missing_licenses)
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
