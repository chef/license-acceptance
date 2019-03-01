require "spec_helper"
require "license_acceptance/product_reader"
require "license_acceptance/product_relationship"

RSpec.describe LicenseAcceptance::ProductReader do
  let(:reader) { LicenseAcceptance::ProductReader.new }
  let(:version) { "0.1.0" }

  describe "#read" do
    it "returns hardcoded values" do
      reader.read
      expect(reader.products).to be_a(Hash)
      expect(reader.relationships).to be_a(Hash)
    end
  end

  describe "::lookup" do
    before do
      reader.read
    end

    it "returns a ProductRelationship instance successfully" do
      expect(reader.lookup("chef_client", version)).to be_an_instance_of(LicenseAcceptance::ProductRelationship) do |instance|
        expect(instance.parent_product).to eq("chef_client")
        expect(instance.children).to_not be_empty
        expect(instance.version).to eq(version)
      end
    end

    describe "when called on an unknown product" do
      it "raises an UnknownProduct error" do
        expect { reader.lookup("DNE", nil) }.to raise_error(LicenseAcceptance::UnknownProduct)
      end
    end

    describe "when called on a product with an unknown relationship" do
      before do
        reader.instance_variable_get(:@products)["nonya"] = LicenseAcceptance::Product.new("nonya", "NonYa")
      end
      after do
        reader.instance_variable_get(:@products).delete("nonya")
      end
      it "raises an NoLicense error" do
        expect { reader.lookup('nonya', nil) }.to raise_error(LicenseAcceptance::NoLicense)
      end
    end

    describe "when called with an invalid parent version type" do
      it "raises an ProductVersionTypeError error" do
        expect { reader.lookup('chef_client', 1) }.to raise_error(LicenseAcceptance::ProductVersionTypeError)
      end
    end
  end

end
