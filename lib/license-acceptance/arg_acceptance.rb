module LicenseAcceptance
  class ArgAcceptance

    def self.check(argv)
      return true if argv.include?("--accept-license=yes")
      i = argv.index("--accept-license")
      return false if i.nil?
      response = argv[i+1]
      return false if response.nil?
      response.downcase == "yes"
    end
end
