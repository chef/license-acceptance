require "spec_helper"
require "license_acceptance/product_set"

RSpec.describe LicenseAcceptance::ProductSet do
  let(:klass) { LicenseAcceptance::ProductSet }

  it "returns a known product" do
    expect(klass["chef_client"]).to be_an_instance_of(LicenseAcceptance::Product)
  end

  it "raises an UnknownProduct error when the product cannot be found" do
    expect {  klass["unknown"] }.to raise_error(LicenseAcceptance::ProductSet::UnknownProduct)
  end

end
