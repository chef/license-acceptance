module LicenseAcceptance
  class ProductSet

    PRODUCT_SET = {
      'chef' => ['inspec'],
      'inspec' => [],
    }.freeze

    attr_reader :parent, :children, :parent_version

    def initialize(parent, children, parent_version)
      @parent = parent
      @children = children
      @parent_version = parent_version
    end

    def self.lookup(parent_product, parent_version)
      children = PRODUCT_SET[parent_product]
      if children.nil?
        raise UnknownProduct.new(parent_product)
      end
      if !parent_version.is_a? String
        raise ProductVersionTypeError.new(parent_version)
      end
      self.new(parent_product, children, parent_version)
    end
  end

  class UnknownProduct < RuntimeError
    def initialize(product)
      msg = "No license information known for product '#{product}'"
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
