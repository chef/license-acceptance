module LicenseAcceptance
  class ProductSet

    PRODUCT_SET = {
      'chef' => ['inspec']
    }.freeze

    attr_reader :parent, :children

    def initialize(parent, children)
      @parent = parent
      @children = children
    end

    def self.lookup(parent_product)
      children = PRODUCT_SET[parent_product]
      if children.nil? || children.empty?
        raise UnknownProduct.new(parent_product)
      end
      self.new(parent_product, children)
    end
  end

  class UnknownProduct < RuntimeError
    def initialize(product)
      msg = "No license information known for product '#{product}'"
      super(msg)
    end
  end
end
