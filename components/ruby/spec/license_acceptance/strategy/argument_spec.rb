require "spec_helper"
require "license_acceptance/strategy/argument"

RSpec.describe LicenseAcceptance::Strategy::Argument do
  let(:acc) { LicenseAcceptance::Strategy::Argument.new(argv) }

  describe "#accepted?" do
    describe "when value is space seperated" do
      let(:argv) { ["--chef-license", "accept"] }
      it "returns true if the args contain the required flag with spaces" do
        expect(acc.accepted?).to eq(true)
      end
    end

    describe "when the value is equal seperated" do
      let(:argv) { ["--chef-license=accept"] }
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
    describe "when value is space seperated" do
      let(:argv) { ["--chef-license", "accept-silent"] }
      it "returns true if the args contain the required flag with spaces" do
        expect(acc.silent?).to eq(true)
      end
    end

    describe "when the value is equal seperated" do
      let(:argv) { ["--chef-license=accept-silent"] }
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
    describe "when value is space seperated" do
      let(:argv) { ["--chef-license", "accept-no-persist"] }
      it "returns true if the args contain the required flag with spaces" do
        expect(acc.no_persist?).to eq(true)
      end
    end

    describe "when the value is equal seperated" do
      let(:argv) { ["--chef-license=accept-no-persist"] }
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

end
