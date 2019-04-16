module LicenseAcceptance
  class EnvAcceptance

    def accepted?(env)
      look_for_value(env, "accept")
    end

    def silent?(env)
      look_for_value(env, "accept-silent")
    end

    def no_persist?(env)
      look_for_value(env, "accept-no-persist")
    end

    private

    def look_for_value(env, sought)
      if env['CHEF_LICENSE'] && env['CHEF_LICENSE'].downcase == sought
        return true
      end
      return false
    end

  end
end
