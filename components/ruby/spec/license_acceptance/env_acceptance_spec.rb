require "spec_helper"
require "license_acceptance/env_acceptance"

RSpec.describe LicenseAcceptance::EnvAcceptance do
  let(:acc) { LicenseAcceptance::EnvAcceptance.new }

  describe "#check" do
    it "returns true if the env contains the correct key and value" do
      env = {"CHEF_LICENSE" => "accept"}
      r = nil
      expect { |b| r = acc.check(env, &b) }.to yield_control
      expect(r).to eq(true)
    end

    it "returns false if the env has a key but nil value" do
      env = {"CHEF_LICENSE" => nil}
      r = nil
      expect { |b| r = acc.check(env, &b) }.to_not yield_control
      expect(r).to eq(false)
    end

    it "returns false if the env has a key but incorrect value" do
      env = {"CHEF_LICENSE" => "foo"}
      r = nil
      expect { |b| r = acc.check(env, &b) }.to_not yield_control
      expect(r).to eq(false)
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
