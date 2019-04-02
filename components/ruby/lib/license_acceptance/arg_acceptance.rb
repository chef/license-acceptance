module LicenseAcceptance
  class ArgAcceptance

    def check(argv, &block)
      if argv.include?("--chef-license=accept")
        block.call
        return true
      end
      i = argv.index("--chef-license")
      unless i.nil?
        val = argv[i+1]
        if val != nil && val.downcase == "accept"
          block.call
          return true
        end
      end
      return false
    end

    def check_no_persist(argv)
      if argv.include?("--chef-license=accept-no-persist")
        return true
      end
      i = argv.index("--chef-license")
      unless i.nil?
        val = argv[i+1]
        if val != nil && val.downcase == "accept-no-persist"
          return true
        end
      end
      return false
    end

  end
end
