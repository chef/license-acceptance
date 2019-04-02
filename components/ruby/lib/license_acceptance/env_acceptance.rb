module LicenseAcceptance
  class EnvAcceptance

    def check(env)
      if env['CHEF_LICENSE'] && env['CHEF_LICENSE'].downcase == 'accept'
        return true
      end
      return false
    end

    def check_no_persist(env)
      if env['CHEF_LICENSE'] && env['CHEF_LICENSE'].downcase == 'accept-no-persist'
        return true
      end
      return false
    end

  end
end
