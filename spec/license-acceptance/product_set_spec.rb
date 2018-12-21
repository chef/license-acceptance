require "spec_helper"
require "license-acceptance/product_set"

RSpec.describe LicenseAcceptance::ProductSet do
  let(:klass) { LicenseAcceptance::ProductSet }
  let(:install_type) { "0.1.0" }

  describe "::lookup" do
    it "returns a ProductSet instance successfully" do
      expect(klass.lookup('chef', install_type)).to be_an_instance_of(klass) do |instance|
        expect(instance.parent_product).to eq('chef')
        expect(instance.children).to_not be_empty
        expect(instance.install_type).to eq(install_type)
      end
    end

    describe "when called on an unknown product" do
      it "raises an UnknownProduct error" do
        expect { klass.lookup('unknown', nil) }.to raise_error(LicenseAcceptance::UnknownProduct)
      end
    end

    describe "when called with an invalid parent version type" do
      it "raises an ProductVersionTypeError error" do
        expect { klass.lookup('chef', 1) }.to raise_error(LicenseAcceptance::ProductVersionTypeError)
      end
    end
  end

end
