module LicenseAcceptance
  class Product

    attr_reader :name, :pretty_name, :filename

    def initialize(name, pretty_name, filename)
      @name = name
      @pretty_name = pretty_name
      @filename = filename
    end

    def ==(other)
      return false if other.class != Product
      if other.name == name &&
         other.pretty_name == pretty_name &&
         other.filename == filename
         return true
      end
      return false
    end

  end
end
