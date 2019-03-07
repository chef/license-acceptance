require "license_acceptance/logger"
require "license_acceptance/product"
require "license_acceptance/product_relationship"

module LicenseAcceptance
  class ProductReader
    include Logger

    attr_accessor :products, :relationships

    # TODO - Eventually this data will be read from a config file in this repo. Provides 1 source of truth for all
    # products and product relationships
    def read
      logger.debug("Reading products and relationships...")
      chef_client = Product.new("chef_client", "Chef Client")
      inspec = Product.new("inspec", "InSpec")
      chef_server = Product.new("chef_server", "Chef Server")
      supermarket = Product.new("supermarket", "Supermarket")
      # The set of unique products, keyed by the product name for quick lookup
     self.products = {
        chef_client.name => chef_client,
        inspec.name => inspec,
        chef_server.name => chef_server,
	      supermarket.name => supermarket,
      }
      self.relationships = {
        chef_client => [inspec],
        inspec => [],
        chef_server => [],
        supermarket => [],
      }
      logger.debug("Successfully read products and relationships")
    end

    def lookup(parent_name, parent_version)
      parent_product = products.fetch(parent_name) do
        raise UnknownProduct.new(parent_name)
      end
      children = relationships[parent_product]
      if children.nil?
        raise NoLicense.new(parent_product)
      end
      if !parent_version.is_a? String
        raise ProductVersionTypeError.new(parent_version)
      end
      ProductRelationship.new(parent_product, children, parent_version)
    end

  end

  class UnknownProduct < RuntimeError
    def initialize(product)
      msg = "Unknown product '#{product}' - this represents a developer error"
      super(msg)
    end
  end

  class NoLicense < RuntimeError
    def initialize(product)
      msg = "No license information known for product '#{product.name}'"
      super(msg)
    end
  end

  class ProductVersionTypeError < RuntimeError
    def initialize(product_version)
      msg = "Product versions must be specified as a string, provided type is '#{product_version.class}'"
      super(msg)
    end
  end
end
