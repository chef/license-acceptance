require "spec_helper"
require "license_acceptance/strategy/argument"

RSpec.describe LicenseAcceptance::Strategy::Argument do
  let(:acc) { LicenseAcceptance::Strategy::Argument.new(argv) }

  describe "#accepted?" do
    describe "when value is space separated" do
      let(:argv) { ["--chef-license", "accept"] }
      it "returns true if the args contain the required flag with spaces" do
        expect(acc.accepted?).to eq(true)
      end
    end

    describe "when value is space separated with a different case" do
      let(:argv) { ["--chef-license", "ACCEPT"] }
      it "returns true if the args contain the required flag with spaces" do
        expect(acc.accepted?).to eq(true)
      end
    end

    describe "when the value is equal separated" do
      let(:argv) { ["--chef-license=accept"] }
      it "returns true if the args contain the required flag with equal" do
        expect(acc.accepted?).to eq(true)
      end
    end

    describe "when the value is equal separated with a different case" do
      let(:argv) { ["--chef-license=ACCEPT"] }
      it "returns true if the args contain the required flag with equal" do
        expect(acc.accepted?).to eq(true)
      end
    end

    [ ["--chef-license"], ["--chef-license=foo"], ["--chef-license", "foo"] ].each do |v|
      describe "when the value is #{v}" do
        let(:argv) { v }
        it "returns false if the args do not contain the required value" do
          expect(acc.accepted?).to eq(false)
        end
      end
    end
  end

  describe "#silent?" do
    describe "when value is space separated" do
      let(:argv) { ["--chef-license", "accept-silent"] }
      it "returns true if the args contain the required flag with spaces" do
        expect(acc.silent?).to eq(true)
      end
    end

    describe "when value is space separated with a different case" do
      let(:argv) { ["--chef-license", "ACCEPT-SILENT"] }
      it "returns true if the args contain the required flag with spaces" do
        expect(acc.silent?).to eq(true)
      end
    end

    describe "when the value is equal separated" do
      let(:argv) { ["--chef-license=accept-silent"] }
      it "returns true if the args contain the required flag with equal" do
        expect(acc.silent?).to eq(true)
      end
    end

    describe "when the value is equal separated with a different case" do
      let(:argv) { ["--chef-license=ACCEPT-SILENT"] }
      it "returns true if the args contain the required flag with equal" do
        expect(acc.silent?).to eq(true)
      end
    end

    [ ["--chef-license"], ["--chef-license=accept"], ["--chef-license", "accept"] ].each do |v|
      describe "when the value is #{v}" do
        let(:argv) { v }
        it "returns false if the args do not contain the required value" do
          expect(acc.silent?).to eq(false)
        end
      end
    end
  end

  describe "#no_persist?" do
    describe "when value is space separated" do
      let(:argv) { ["--chef-license", "accept-no-persist"] }
      it "returns true if the args contain the required flag with spaces" do
        expect(acc.no_persist?).to eq(true)
      end
    end

    describe "when value is space separated with a different case" do
      let(:argv) { ["--chef-license", "ACCEPT-NO-PERSIST"] }
      it "returns true if the args contain the required flag with spaces" do
        expect(acc.no_persist?).to eq(true)
      end
    end

    describe "when the value is equal separated" do
      let(:argv) { ["--chef-license=accept-no-persist"] }
      it "returns true if the args contain the required flag with equal" do
        expect(acc.no_persist?).to eq(true)
      end
    end

    describe "when the value is equal separated with a different case" do
      let(:argv) { ["--chef-license=ACCEPT-NO-PERSIST"] }
      it "returns true if the args contain the required flag with equal" do
        expect(acc.no_persist?).to eq(true)
      end
    end

    [ ["--chef-license"], ["--chef-license=accept"], ["--chef-license", "accept"] ].each do |v|
      describe "when the value is #{v}" do
        let(:argv) { v }
        it "returns false if the args do not contain the required value" do
          expect(acc.no_persist?).to eq(false)
        end
      end
    end
  end

  describe "#value?" do
    describe "when value is space separated" do
      let(:argv) { ["--chef-license", "any-value"] }
      it "returns true if the required flag is present" do
        expect(acc.value?).to eq(true)
      end
    end

    describe "when the value is equal separated" do
      let(:argv) { ["--chef-license=any-value"] }
      it "returns true if the required flag is present" do
        expect(acc.value?).to eq(true)
      end
    end

    describe "when no value is present" do
      let(:argv) { ["--chef-license"] }
      it "returns true if the required flag is present" do
        expect(acc.value?).to eq(true)
      end
    end

    describe "when the required flag is not present" do
      let(:argv) { ["--chef-license-acceptance=yes"] }
      it "returns false" do
        expect(acc.value?).to eq(false)
      end
    end
  end

  describe "#value" do
    describe "when value is space separated" do
      let(:argv) { ["--chef-license", "any-value"] }
      it "returns the value" do
        expect(acc.value).to eq("any-value")
      end
    end

    describe "when the value is equal separated" do
      let(:argv) { ["--chef-license=any-value"] }
      it "returns the value" do
        expect(acc.value).to eq("any-value")
      end
    end

    describe "when no value is present" do
      let(:argv) { ["--chef-license"] }
      it "returns nil" do
        expect(acc.value).to eq(nil)
      end
    end

    describe "when the required flag is not present" do
      let(:argv) { ["--chef-license-acceptance=yes"] }
      it "returns nil" do
        expect(acc.value).to eq(nil)
      end
    end
  end
end
