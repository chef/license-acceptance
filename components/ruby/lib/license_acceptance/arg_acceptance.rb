module LicenseAcceptance
  class ArgAcceptance

    def accepted?(argv)
      look_for_value(argv, "accept")
    end

    def silent?(argv)
      look_for_value(argv, "accept-silent")
    end

    def no_persist?(argv)
      look_for_value(argv, "accept-no-persist")
    end

    private

    def look_for_value(argv, sought)
      if argv.include?("--chef-license=#{sought}")
        return true
      end
      i = argv.index("--chef-license")
      unless i.nil?
        val = argv[i+1]
        if val != nil && val.downcase == sought
          return true
        end
      end
      return false
    end
  end
end
