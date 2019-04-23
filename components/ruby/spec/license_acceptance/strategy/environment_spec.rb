require "spec_helper"
require "license_acceptance/strategy/environment"

RSpec.describe LicenseAcceptance::Strategy::Environment do
  let(:acc) { LicenseAcceptance::Strategy::Environment.new(env) }

  describe "#accepted?" do
    describe "when the environment contains the correct key and value" do
      let(:env) { {"CHEF_LICENSE" => "accept"} }
      it "returns true" do
        expect(acc.accepted?).to eq(true)
      end
    end

    describe "when the env has a key but nil value" do
      let(:env) { {"CHEF_LICENSE" => nil} }
      it "returns false" do
        expect(acc.accepted?).to eq(false)
      end
    end

    describe "when the env has a key but incorrect value" do
      let(:env) { {"CHEF_LICENSE" => "foo"} }
      it "returns false" do
        expect(acc.accepted?).to eq(false)
      end
    end
  end

  describe "#silent?" do
    describe "when the environment contains the correct key and value" do
      let(:env) { {"CHEF_LICENSE" => "accept-silent"} }
      it "returns true" do
        expect(acc.silent?).to eq(true)
      end
    end

    describe "when the env has a key but nil value" do
      let(:env) { {"CHEF_LICENSE" => nil} }
      it "returns false" do
        expect(acc.silent?).to eq(false)
      end
    end

    describe "when the env has a key but incorrect value" do
      let(:env) { {"CHEF_LICENSE" => "accept"} }
      it "returns false" do
        expect(acc.silent?).to eq(false)
      end
    end
  end

  describe "#no_persist?" do
    describe "when the environment contains the correct key and value" do
      let(:env) { {"CHEF_LICENSE" => "accept-no-persist"} }
      it "returns true" do
        expect(acc.no_persist?).to eq(true)
      end
    end

    describe "when the env has a key but nil value" do
      let(:env) { {"CHEF_LICENSE" => nil} }
      it "returns false" do
        expect(acc.no_persist?).to eq(false)
      end
    end

    describe "when the env has a key but incorrect value" do
      let(:env) { {"CHEF_LICENSE" => "accept-silent"} }
      it "returns false" do
        expect(acc.no_persist?).to eq(false)
      end
    end
  end

end
