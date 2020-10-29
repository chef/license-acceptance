require "spec_helper"
require "license_acceptance/license_list"

RSpec.describe LicenseAcceptance::LicenseList do
  let(:ll) { LicenseAcceptance::LicenseList }

  describe "lookup" do
    it "returns the EULA" do
      expect(ll.lookup("EULA")).to eq(ll::EULA)
    end

    it "returns the MLSA" do
      expect(ll.lookup("MLSA")).to eq(ll::MLSA)
    end

    describe "when looking up an unknown license" do
      it "raises an errors" do
        expect { ll.lookup("nonya") }.to raise_error(LicenseAcceptance::LicenseList::UnknownLicense)
      end
    end
  end

end
