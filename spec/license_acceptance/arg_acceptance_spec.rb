require "spec_helper"
require "license_acceptance/arg_acceptance"

RSpec.describe LicenseAcceptance::ArgAcceptance do
  let(:klass) { LicenseAcceptance::ArgAcceptance }

  describe "#check" do
    it "returns true if the args contain the required flag" do
      r = nil
      expect { |b| r = klass.check(["--accept-license"], &b) }.to yield_control
      expect(r).to eq(true)
    end

    it "returns false if the args do not contain the required flag" do
      r = nil
      expect { |b| r = klass.check(["--other"], &b) }.to_not yield_control
      expect(r).to eq(false)
    end
  end

end
