require "spec_helper"
require "license_acceptance/product"
require "license_acceptance/license"

RSpec.describe LicenseAcceptance::Product do
  let(:p1) { { id: "p1", pretty_name: "P1", filename: "f1", mixlib_name: "p1m", license_required_version: "p1v", license: "EULA" } }
  describe "#new" do
    it "sets the properties" do
      product = LicenseAcceptance::Product.new(p1)
      expect(product.id).to eq p1[:id]
      expect(product.pretty_name).to eq p1[:pretty_name]
      expect(product.filename).to eq p1[:filename]
      expect(product.mixlib_name).to eq p1[:mixlib_name]
      expect(product.license_required_version).to eq p1[:license_required_version]
      expect(product.license.name).to eq p1[:license]
    end
  end

  describe ".license=" do
    it "boosts strings to real License values" do
      product = LicenseAcceptance::Product.new(p1)
      product.license = "MLSA"
      expect(product.license).to be_kind_of LicenseAcceptance::License
    end

    it "prevents setting invalid values" do
      product = LicenseAcceptance::Product.new(p1)
      expect { product.license = "NOPE" }.to raise_error(LicenseAcceptance::LicenseList::UnknownLicense)
    end
  end
end
