require "spec_helper"
require "license_acceptance/config"
require "license_acceptance/product_relationship"

RSpec.describe LicenseAcceptance::Config do
  let(:opts) { {} }
  let(:config) { LicenseAcceptance::Config.new(opts) }

  it "loads correctly with default values" do
    config
  end

  describe "with overwritten values" do
    let(:output) { StringIO.new }
    let(:logger) { "logger" }
    let(:license_locations) { [] }
    let(:opts) { { output: output, logger: logger, license_locations: license_locations } }

    it "loads correctly" do
      expect(config.output).to eq(output)
      expect(config.logger).to eq(logger)
      expect(config.license_locations).to eq(license_locations)
      expect(config.persist_location).to eq(nil)
    end
  end

end
