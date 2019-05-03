require "spec_helper"
require "license_acceptance/product"

RSpec.describe LicenseAcceptance::Product do
  let(:instance) { LicenseAcceptance::Product.new("id", "Pretty Name", "filename", "mixlib_name", "version") }

  it "can lookup the product attributes" do
    expect(instance.id).to eq("id")
    expect(instance.pretty_name).to eq("Pretty Name")
    expect(instance.filename).to eq("filename")
    expect(instance.mixlib_name).to eq("mixlib_name")
    expect(instance.license_required_version).to eq("version")
  end

end
