require "spec_helper"
require "climate_control"
require "license_acceptance/config"
require "license_acceptance/product_relationship"

RSpec.describe LicenseAcceptance::Config do
  let(:opts) { {} }
  let(:config) { LicenseAcceptance::Config.new(opts) }
  let(:platform) { instance_double(TTY::Platform) }

  it "loads correctly with default values" do
    config
  end

  describe "with overwritten values" do
    let(:output) { StringIO.new }
    let(:logger) { "logger" }
    let(:license_locations) { [] }
    let(:persist_location) { "foo" }
    let(:persist) { false }
    let(:opts) { { output: output, logger: logger, license_locations: license_locations, persist_location: persist_location, persist: persist } }

    it "loads correctly" do
      expect(config.output).to eq(output)
      expect(config.logger).to eq(logger)
      expect(config.license_locations).to eq(license_locations)
      expect(config.persist_location).to eq("foo")
      expect(config.persist).to eq(false)
    end
  end

  describe "#default_license_locations and #default_persist_location" do
    before do
      expect(TTY::Platform).to receive(:new).and_return(platform)
      expect(Process).to receive(:uid).and_return(uid)
    end

    describe "when platform is Windows" do
      before do
        expect(platform).to receive(:windows?).and_return(true)
      end

      describe "when user is Administrator" do
        let(:uid) { 0 }

        it "returns the default value" do
          ClimateControl.modify HOMEDRIVE: "C:" do
            expect(config.license_locations).to eq(["C:/chef/accepted_licenses/"])
            expect(config.persist_location).to eq("C:/chef/accepted_licenses/")
          end
        end
      end

      describe "when user is not Administrator" do
        let(:uid) { 1000 }

        it "returns the default USERPROFILE value" do
          ClimateControl.modify HOMEDRIVE: "C:", USERPROFILE: "C:/Users/foo", HOME: nil do
            expect(Dir).to receive(:exist?).with("C:/Users/foo").and_return(true)
            expect(config.license_locations).to eq([
              "C:/chef/accepted_licenses/",
              "C:/Users/foo/.chef/accepted_licenses/"
            ])
            expect(config.persist_location).to eq("C:/Users/foo/.chef/accepted_licenses/")
          end
        end

        it "returns the default HOMEDRIVE + HOMEPATH value" do
          ClimateControl.modify HOMEDRIVE: "C:", USERPROFILE: "C:/Users/bar", HOME: nil do
            expect(Dir).to receive(:exist?).with("C:/Users/bar").and_return(true)
            expect(config.license_locations).to eq([
              "C:/chef/accepted_licenses/",
              "C:/Users/bar/.chef/accepted_licenses/"
            ])
            expect(config.persist_location).to eq("C:/Users/bar/.chef/accepted_licenses/")
          end
        end
      end

    end

    describe "when platform is non-Windows" do
      before do
        expect(platform).to receive(:windows?).and_return(false)
      end

      describe "when user is root" do
        let(:uid) { 0 }

        it "returns the default value" do
          expect(config.license_locations).to eq(["/etc/chef/accepted_licenses/"])
          expect(config.persist_location).to eq("/etc/chef/accepted_licenses/")
        end
      end

      describe "when user is not root" do
        let(:uid) { 1000 }

        it "returns the default user value" do
          ClimateControl.modify HOME: "/Users/foo" do
            expect(config.license_locations).to eq([
              "/etc/chef/accepted_licenses/",
              "/Users/foo/.chef/accepted_licenses/"
            ])
            expect(config.persist_location).to eq("/Users/foo/.chef/accepted_licenses/")
          end
        end
      end

    end
  end

end
