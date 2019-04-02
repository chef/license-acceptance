require "spec_helper"
require "license_acceptance/product_reader"
require "license_acceptance/product_relationship"

RSpec.describe LicenseAcceptance::ProductReader do
  let(:reader) { LicenseAcceptance::ProductReader.new }
  let(:version) { "0.1.0" }
  let(:location) { "location" }

  let(:p1) { {"name" => "p1", "pretty_name" => "P1", "filename" => "f1"} }
  let(:p2) { {"name" => "p2", "pretty_name" => "P2", "filename" => "f2"} }
  # defined the `==` operator on Product for ease of comparison
  let(:product1) { LicenseAcceptance::Product.new(p1["name"], p1["pretty_name"], p1["filename"]) }
  let(:product2) { LicenseAcceptance::Product.new(p2["name"], p2["pretty_name"], p2["filename"]) }
  let(:r1) { {p1 => p2} }
  let(:toml) { {"products" => [p1, p2], "relationships" => {"p1" => ["p2"]}} }

  describe "#read" do
    it "reads products and relationships" do
      expect(reader).to receive(:get_location).and_return(location)
      expect(Tomlrb).to receive(:load_file).with(location, symbolize_keys: false).and_return(toml)
      reader.read
      expect(reader.products).to eq({
        "p1" => product1,
        "p2" => product2
      })
      expect(reader.relationships.size).to eq(1)
      expect(reader.relationships.first).to eq([product1, [product2]])
    end

    describe "with an empty file" do
      it "raises a InvalidProductInfo error" do
        expect(reader).to receive(:get_location).and_return(location)
        expect(Tomlrb).to receive(:load_file).with(location, symbolize_keys: false).and_return({})

        expect { reader.read }.to raise_error(LicenseAcceptance::InvalidProductInfo)
      end
    end

    describe "with an unknown parent" do
      let(:toml) { {"products" => [p1, p2], "relationships" => {"p3" => ["p2"]}} }

      it "raises a UnknownParent error" do
        expect(reader).to receive(:get_location).and_return(location)
        expect(Tomlrb).to receive(:load_file).with(location, symbolize_keys: false).and_return(toml)

        expect { reader.read }.to raise_error(LicenseAcceptance::UnknownParent)
      end
    end

    describe "with a relationship of nil children" do
      let(:toml) { {"products" => [p1], "relationships" => {"p1" => nil}} }

      it "raises a NoChildRelationships error" do
        expect(reader).to receive(:get_location).and_return(location)
        expect(Tomlrb).to receive(:load_file).with(location, symbolize_keys: false).and_return(toml)

        expect { reader.read }.to raise_error(LicenseAcceptance::NoChildRelationships)
      end
    end

    describe "with a relationship of empty children" do
      let(:toml) { {"products" => [p1], "relationships" => {"p1" => []}} }

      it "raises a NoChildRelationships error" do
        expect(reader).to receive(:get_location).and_return(location)
        expect(Tomlrb).to receive(:load_file).with(location, symbolize_keys: false).and_return(toml)

        expect { reader.read }.to raise_error(LicenseAcceptance::NoChildRelationships)
      end
    end

    describe "with a relationship of non-array children" do
      let(:toml) { {"products" => [p1], "relationships" => {"p1" => "p2"}} }

      it "raises a NoChildRelationships error" do
        expect(reader).to receive(:get_location).and_return(location)
        expect(Tomlrb).to receive(:load_file).with(location, symbolize_keys: false).and_return(toml)

        expect { reader.read }.to raise_error(LicenseAcceptance::NoChildRelationships)
      end
    end

    describe "with an unknown child" do
      let(:toml) { {"products" => [p1, p2], "relationships" => {"p1" => ["p2", "p3"]}} }

      it "raises a UnknownChild error" do
        expect(reader).to receive(:get_location).and_return(location)
        expect(Tomlrb).to receive(:load_file).with(location, symbolize_keys: false).and_return(toml)

        expect { reader.read }.to raise_error(LicenseAcceptance::UnknownChild)
      end
    end
  end

  describe "::lookup" do
    before do
      expect(reader).to receive(:get_location).and_return(location)
      expect(Tomlrb).to receive(:load_file).with(location, symbolize_keys: false).and_return(toml)
      reader.read
    end

    it "returns a ProductRelationship instance successfully" do
      expect(reader.lookup("p1", version)).to be_an_instance_of(LicenseAcceptance::ProductRelationship) do |instance|
        expect(instance.parent_product).to eq(product1)
        expect(instance.children).to eq([prouct2])
        expect(instance.version).to eq(version)
      end
    end

    describe "when called on an unknown product" do
      it "raises an UnknownProduct error" do
        expect { reader.lookup("DNE", nil) }.to raise_error(LicenseAcceptance::UnknownProduct)
      end
    end

    let(:nonya) { LicenseAcceptance::Product.new("nonya", "NonYa", "nofile") }
    describe "when called on a product with no relationship" do
      before do
        reader.products = { "nonya" => nonya }
      end

      it "returns the product" do
        expect(reader.lookup('nonya', version)).to be_an_instance_of(LicenseAcceptance::ProductRelationship) do |instance|
          expect(instance.parent_product).to eq(nonya)
          expect(instance.children).to eq([])
          expect(instance.version).to eq(version)
        end
      end
    end

    describe "when called with an invalid parent version type" do
      it "raises an ProductVersionTypeError error" do
        expect { reader.lookup("p1", 1) }.to raise_error(LicenseAcceptance::ProductVersionTypeError)
      end
    end
  end

end
