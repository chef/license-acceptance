require "spec_helper"
require "license_acceptance/arg_acceptance"

RSpec.describe LicenseAcceptance::ArgAcceptance do
  let(:acc) { LicenseAcceptance::ArgAcceptance.new }

  describe "#check" do
    it "returns true if the args contain the required flag with spaces" do
      r = nil
      expect { |b| r = acc.check(["--chef-license", "accept"], &b) }.to yield_control
      expect(r).to eq(true)
    end

    it "returns true if the args contain the required flag with equal" do
      r = nil
      expect { |b| r = acc.check(["--chef-license=accept"], &b) }.to yield_control
      expect(r).to eq(true)
    end

    it "returns false if the args do not contain the required value" do
      r = nil
      expect { |b| r = acc.check(["--chef-license", "foo"], &b) }.to_not yield_control
      expect(r).to eq(false)
      expect { |b| r = acc.check(["--chef-license"], &b) }.to_not yield_control
      expect(r).to eq(false)
    end
  end

  describe "#check_no_persist" do
    it "returns true if the args contain the required flag with spaces" do
      expect(acc.check_no_persist(["--chef-license", "accept-no-persist"])).to eq(true)
    end

    it "returns true if the args contain the required flag with equal" do
      expect(acc.check_no_persist(["--chef-license=accept-no-persist"])).to eq(true)
    end

    it "returns false if the args do not contain the required value" do
      expect(acc.check_no_persist(["--chef-license"])).to eq(false)
      expect(acc.check_no_persist(["--chef-license=accept"])).to eq(false)
      expect(acc.check_no_persist(["--chef-license","accept"])).to eq(false)
    end
  end

end
