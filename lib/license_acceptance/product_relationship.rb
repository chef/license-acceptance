require "license_acceptance/product_set"

module LicenseAcceptance
  class ProductRelationship

    CHEF = ProductSet["chef"]
    INSPEC = ProductSet["inspec"]
    KNOWN_RELATIONSHIPS = {
      CHEF => [INSPEC],
      INSPEC => []
    }.freeze

    attr_reader :parent, :children, :parent_version

    def initialize(parent, children, parent_version)
      @parent = parent
      @children = children
      @parent_version = parent_version
    end

    def self.lookup(parent_name, parent_version)
      parent_product = ProductSet[parent_name]
      children = KNOWN_RELATIONSHIPS[parent_product]
      if children.nil?
        raise NoLicense.new(parent_product)
      end
      if !parent_version.is_a? String
        raise ProductVersionTypeError.new(parent_version)
      end
      self.new(parent_product, children, parent_version)
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
