require "spec_helper"
require "license_acceptance/arg_acceptance"

RSpec.describe LicenseAcceptance::ArgAcceptance do
  let(:acc) { LicenseAcceptance::ArgAcceptance.new }

  describe "#check" do
    it "returns true if the args contain the required flag" do
      r = nil
      expect { |b| r = acc.check(["--accept-license"], &b) }.to yield_control
      expect(r).to eq(true)
    end

    it "returns false if the args do not contain the required flag" do
      r = nil
      expect { |b| r = acc.check(["--other"], &b) }.to_not yield_control
      expect(r).to eq(false)
    end
  end

end
