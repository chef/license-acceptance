require "spec_helper"
require "license_acceptance/env_acceptance"

RSpec.describe LicenseAcceptance::EnvAcceptance do
  let(:acc) { LicenseAcceptance::EnvAcceptance.new }

  describe "when passed an accept value" do
    describe "#check" do
      it "returns true if the env contains the correct key and value" do
        env = {"CHEF_LICENSE" => "accept"}
        expect(acc.check(env)).to eq(true)
      end

      it "returns false if the env has a key but nil value" do
        env = {"CHEF_LICENSE" => nil}
        expect(acc.check(env)).to eq(false)
      end

      it "returns false if the env has a key but incorrect value" do
        env = {"CHEF_LICENSE" => "foo"}
        expect(acc.check(env)).to eq(false)
      end
    end

    describe "#silent?" do
      it "returns true if the env contains the correct key and value" do
        env = {"CHEF_LICENSE" => "accept-silent"}
        expect(acc.silent?(env)).to eq(true)
      end

      it "returns false if the env has a key but nil value" do
        env = {"CHEF_LICENSE" => nil}
        expect(acc.silent?(env)).to eq(false)
      end

      it "returns false if the env has a key but incorrect value" do
        env = {"CHEF_LICENSE" => "foo"}
        expect(acc.silent?(env)).to eq(false)
      end
    end

  end

  describe "#check_no_persist" do
    it "returns true if the env contains the correct key and value" do
      env = {"CHEF_LICENSE" => "accept-no-persist"}
      expect(acc.check_no_persist(env)).to eq(true)
    end

    it "returns false if the env has a key but nil value" do
      env = {"CHEF_LICENSE" => nil}
      expect(acc.check_no_persist(env)).to eq(false)
    end

    it "returns false if the env has a key but incorrect value" do
      env = {"CHEF_LICENSE" => "foo"}
      expect(acc.check_no_persist(env)).to eq(false)
      env = {"CHEF_LICENSE" => "accept"}
      expect(acc.check_no_persist(env)).to eq(false)
    end
  end

end
