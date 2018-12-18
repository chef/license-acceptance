require "license-acceptance/product_set"

RSpec.describe LicenseAcceptance::ProductSet do
  let(:klass) { LicenseAcceptance::ProductSet }

  describe "::lookup" do
    it "returns a ProductSet instance successfully" do
      expect(klass.lookup('chef')).to be_an_instance_of(klass) do |instance|
        expect(instance.parent_product).to eq('chef')
        expect(instance.children).to_not be_empty
      end
    end

    describe "when called on an unknown product" do
      it "raises an UnknownProduct error" do
        expect { klass.lookup('unknown') }.to raise_error(LicenseAcceptance::UnknownProduct)
      end
    end
  end

end
