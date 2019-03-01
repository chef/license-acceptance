module LicenseAcceptance
  class Product

    attr_reader :name, :pretty_name

    def initialize(name, pretty_name)
      @name = name
      @pretty_name = pretty_name
    end

  end
end
