# We were getting too many args in the Product initialize method so switching to the builder
# pattern. We also need to now validate the license_name
require_relative('product')
require_relative('license_list')

module LicenseAcceptance
  class ProductBuilder
    def self.build
      builder = new
      yield(builder)
      builder.product
    end

    attr_reader :product

    def initialize
      @product = Product.new
    end

    def set_id(id)
      product.id = id
    end

    def set_pretty_name(pretty_name)
      product.pretty_name = pretty_name
    end

    def set_filename(filename)
      product.filename = filename
    end

    def set_mixlib_name(mixlib_name)
      product.mixlib_name = mixlib_name
    end

    def set_license_required_version(license_required_version)
      product.license_required_version = license_required_version
    end

    def set_license(license_name)
      product.license = LicenseList.lookup(license_name)
    end

  end
end
