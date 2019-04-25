module LicenseAcceptance
  class Product

    attr_reader :name, :pretty_name, :filename, :mixlib_name, :license_required_version

    def initialize(name, pretty_name, filename, mixlib_name, license_required_version)
      @name = name
      @pretty_name = pretty_name
      @filename = filename
      @mixlib_name = mixlib_name
      @license_required_version = license_required_version
    end

    def ==(other)
      return false if other.class != Product
      if other.name == name &&
         other.pretty_name == pretty_name &&
         other.filename == filename &&
         other.mixlib_name == mixlib_name
         other.license_required_version == license_required_version
         return true
      end
      return false
    end

  end
end
