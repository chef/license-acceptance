require_relative("license_list")

module LicenseAcceptance
  class Product

    attr_accessor :id, :pretty_name, :filename, :mixlib_name, :license_required_version

    attr_reader :license

    def initialize(opts)
      @id = opts[:id]
      @pretty_name = opts[:pretty_name]
      @filename = opts[:filename]
      @mixlib_name = opts[:mixlib_name]
      @license_required_version = opts[:license_required_version]
      self.license = opts[:license]
    end

    def license=(license_name)
      @license = LicenseList.lookup(license_name)
    end
  end
end
