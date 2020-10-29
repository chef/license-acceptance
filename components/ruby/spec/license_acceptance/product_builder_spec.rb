require "spec_helper"
require "license_acceptance/product_builder"
require "license_acceptance/license_list"
require "license_acceptance/license"

RSpec.describe LicenseAcceptance::ProductBuilder do
  let(:builder) { LicenseAcceptance::ProductBuilder }
  let(:version) { "0.1.0" }
  let(:location) { "location" }

  let(:h1) { { id: "p1", pretty_name: "P1", filename: "f1", mixlib_name: "m1", license_required_version: "v1", license: { name: "FOO", uri: "http://foo" } } }
  let(:l1){ LicenseAcceptance::License.new(h1[:license][:name], h1[:license][:uri]) }
  let(:p1) {
    p = LicenseAcceptance::Product.new
    p.id = h1[:id]
    p.pretty_name = h1[:pretty_name]
    p.filename = h1[:filename]
    p.mixlib_name = h1[:mixlib_name]
    p.license_required_version = h1[:license_required_version]
    p.license = l1
    p
  }

  describe "build" do
    before do
      expect(LicenseAcceptance::LicenseList).to receive(:lookup).with(h1[:license][:name]).and_return(l1)
    end

    it "builds and returns a product correctly" do
      actual = builder.build do |b|
        b.set_id h1[:id]
        b.set_pretty_name h1[:pretty_name]
        b.set_filename h1[:filename]
        b.set_mixlib_name h1[:mixlib_name]
        b.set_license_required_version h1[:license_required_version]
        b.set_license h1[:license][:name]
      end
      expect(p1).to eq(actual)
    end
  end

end
