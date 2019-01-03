module LicenseAcceptance
  class ArgAcceptance

    def self.check(argv)
      return true if argv.include?("--accept-license")
      return false
    end

  end
end
