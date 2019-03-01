require "spec_helper"
require "license_acceptance/product"

RSpec.describe LicenseAcceptance::Product do
  let(:instance) { LicenseAcceptance::Product.new("name", "Pretty Name") }

  it "can lookup the product attributes" do
    expect(instance.name).to eq("name")
    expect(instance.pretty_name).to eq("Pretty Name")
  end

end
