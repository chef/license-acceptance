module LicenseAcceptance
  class License

    attr_reader :name, :uri

    def initialize(name, uri)
      @name = name
      @uri = uri
    end

  end
end
