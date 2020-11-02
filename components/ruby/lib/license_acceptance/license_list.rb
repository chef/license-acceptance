require_relative "license"

# Licenses should not be able to be defined via a toml file, so we hardcode them.
# They may change in the future (new attrs, versions, etc.) but should not be
# user definable.
module LicenseAcceptance
  class LicenseList

    EULA = License.new("EULA", "https://www.chef.io/end-user-license-agreement/")
    MLSA = License.new("MLSA", "https://www.chef.io/online-master-agreement/")

    def self.lookup(name)
      case name
      when "EULA"
        EULA
      when "MLSA"
        MLSA
      else
        raise UnknownLicense.new(name)
      end
    end

    class UnknownLicense < RuntimeError
      def initialize(name)
        msg = "Unknown license named #{name}"
        super(msg)
      end
    end

  end
end
