require "spec_helper"
require "license_acceptance/product_relationship"
require "license_acceptance/product_set"
require "license_acceptance/product"

RSpec.describe LicenseAcceptance::ProductRelationship do
  let(:klass) { LicenseAcceptance::ProductRelationship }
  let(:version) { "0.1.0" }

  describe "::lookup" do
    it "returns a ProductRelationship instance successfully" do
      expect(klass.lookup('chef_client', version)).to be_an_instance_of(klass) do |instance|
        expect(instance.parent_product).to eq('chef_client')
        expect(instance.children).to_not be_empty
        expect(instance.version).to eq(version)
      end
    end

    describe "when called on a product with an unknown relationship" do
      before do
        LicenseAcceptance::ProductSet::PRODUCT_SET["nonya"] = LicenseAcceptance::Product.new("nonya", "NonYa")
      end
      after do
        LicenseAcceptance::ProductSet::PRODUCT_SET.delete("nonya")
      end
      it "raises an NoLicense error" do
        expect { klass.lookup('nonya', nil) }.to raise_error(LicenseAcceptance::NoLicense)
      end
    end

    describe "when called with an invalid parent version type" do
      it "raises an ProductVersionTypeError error" do
        expect { klass.lookup('chef_client', 1) }.to raise_error(LicenseAcceptance::ProductVersionTypeError)
      end
    end
  end

end
