require "license_acceptance/product"

module LicenseAcceptance
  class ProductSet

    # The set of unique products, keyed by the product name for quick lookup
    PRODUCT_SET = {
      "chef" => Product.new("chef", "Chef"),
      "inspec" => Product.new("inspec", "InSpec")
    }.freeze

    def self.[](name)
      PRODUCT_SET.fetch(name) do
        raise UnknownProduct.new(name)
      end
    end

    # This is the database of known products. If it is not in here, we need to
    # add it
    class UnknownProduct < RuntimeError
      def initialize(product)
        msg = "Unknown product '#{product}' - this represents a developer error"
        super(msg)
      end
    end

  end
end
