require "tomlrb"
require "license_acceptance/logger"
require "license_acceptance/product"
require "license_acceptance/product_relationship"

module LicenseAcceptance
  class ProductReader
    include Logger

    attr_accessor :products, :relationships

    def read
      logger.debug("Reading products and relationships...")
      location = get_location
      self.products = {}
      self.relationships = {}

      toml = Tomlrb.load_file(location, symbolize_keys: false)
      raise InvalidProductInfo.new(location) if toml.empty? || toml["products"].nil? || toml["relationships"].nil?

      for product in toml["products"]
        products[product["name"]] = Product.new(product["name"], product["pretty_name"], product["filename"])
      end

      for parent_name, children in toml["relationships"]
        parent = products[parent_name]
        raise UnknownParent.new(parent_name) if parent.nil?
        children.map! do |child_name|
          child = products[child_name]
          raise UnknownChild.new(child_name) if child.nil?
          child
        end
        relationships[parent] = children
      end

      logger.debug("Successfully read products and relationships")
    end

    def get_location
      location = "../../../config/product_info.toml"
      if ENV["CHEF_LICENSE_PRODUCT_INFO"]
        location = ENV["CHEF_LICENSE_PRODUCT_INFO"]
      end
      File.absolute_path(File.join(__FILE__, location))
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

  class InvalidProductInfo < RuntimeError
    def initialize(path)
      msg = "Product info at path #{path} is invalid. Must list Products and relationships."
      super(msg)
    end
  end

  class UnknownParent < RuntimeError
    def initialize(product)
      msg = "Could not find product #{product} from relationship parents"
      super(msg)
    end
  end

  class UnknownChild < RuntimeError
    def initialize(product)
      msg = "Could not find product #{product} from relationship children"
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
