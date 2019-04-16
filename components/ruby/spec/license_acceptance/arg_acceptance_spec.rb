require "spec_helper"
require "license_acceptance/arg_acceptance"

RSpec.describe LicenseAcceptance::ArgAcceptance do
  let(:acc) { LicenseAcceptance::ArgAcceptance.new }

  describe "with an accept option" do
    describe "#check" do
      it "returns true if the args contain the required flag with spaces" do
        expect(acc.check(["--chef-license", "accept"])).to eq(true)
      end

      it "returns true if the args contain the required flag with equal" do
        expect(acc.check(["--chef-license=accept"])).to eq(true)
      end

      it "returns false if the args do not contain the required value" do
        expect(acc.check(["--chef-license"])).to eq(false)
      end
    end

    describe "#silent?" do
      it "returns false if the args contain the required flag with spaces" do
        expect(acc.silent?(["--chef-license", "accept"])).to eq(false)
      end

      it "returns false if the args contain the required flag with equal" do
        expect(acc.silent?(["--chef-license=accept"])).to eq(false)
      end
    end
  end

  describe "with a silent option" do
    describe "#check" do
      it "returns true if the args contain the required flag with spaces" do
        expect(acc.check(["--chef-license", "accept-silent"])).to eq(true)
      end

      it "returns true if the args contain the required flag with equal" do
        expect(acc.check(["--chef-license=accept-silent"])).to eq(true)
      end
    end

    describe "#silent?" do
      it "returns true if the args contain the required flag with spaces" do
        expect(acc.silent?(["--chef-license", "accept-silent"])).to eq(true)
      end

      it "returns true if the args contain the required flag with equal" do
        expect(acc.silent?(["--chef-license=accept-silent"])).to eq(true)
      end
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
