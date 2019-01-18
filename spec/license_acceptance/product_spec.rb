require "spec_helper"
require "license_acceptance/product"

RSpec.describe LicenseAcceptance::Product do
  let(:instance) { LicenseAcceptance::Product.new("chef", "Chef") }

  it "can lookup the product attributes" do
    expect(instance.name).to eq("chef")
    expect(instance.pretty_name).to eq("Chef")
  end

end
