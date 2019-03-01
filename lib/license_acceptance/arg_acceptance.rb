module LicenseAcceptance
  class ArgAcceptance

    def check(argv, &block)
      if argv.include?("--accept-license")
        block.call
        return true
      end
      return false
    end

  end
end
