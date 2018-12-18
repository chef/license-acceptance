module LicenseAcceptance
  class ProductSet

    attr_reader :parent, :children

    def initialize(parent, children)
      @parent = parent
      @children = children
    end

    PRODUCT_SET = {
      'chef' => ['inspec']
    }.freeze

    def self.lookup(parent_product)
      children = PRODUCT_SET[parent_product]
      if children.nil?
        raise UnknownProduct.new(parent_product)
      end
      self.klass.new(parent_product, children)
    end
  end

  class UnknownProduct < RuntimeError
    def initialize(product)
      msg = "No license information known for product '#{product}'"
      super(msg)
    end
  end
end
