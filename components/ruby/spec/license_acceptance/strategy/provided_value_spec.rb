require "spec_helper"
require "license_acceptance/strategy/provided_value"

RSpec.describe LicenseAcceptance::Strategy::ProvidedValue do
  let(:acc) { LicenseAcceptance::Strategy::ProvidedValue.new(value) }

  describe "#accepted?" do
    describe "when the value is correct" do
      let(:value) { "accept" }
      it "returns true" do
        expect(acc.accepted?).to eq(true)
      end
    end

    describe "when the value is incorrect" do
      let(:value) { nil }
      it "returns false" do
        expect(acc.accepted?).to eq(false)
      end
    end
  end

  describe "#silent?" do
    describe "when the value is correct" do
      let(:value) { "accept-silent" }
      it "returns true" do
        expect(acc.silent?).to eq(true)
      end
    end

    describe "when the value is incorrect" do
      let(:value) { "accept" }
      it "returns false" do
        expect(acc.silent?).to eq(false)
      end
    end
  end

  describe "#no_persist?" do
    describe "when the value is correct" do
      let(:value) { "accept-no-persist" }
      it "returns true" do
        expect(acc.no_persist?).to eq(true)
      end
    end

    describe "when the value is incorrect" do
      let(:value) { "accept-silent" }
      it "returns false" do
        expect(acc.no_persist?).to eq(false)
      end
    end
  end

  describe "#value?" do
    describe "when the value is present" do
      let(:value) { "any-value" }
      it "returns true" do
        expect(acc.value?).to eq(true)
      end
    end

    describe "when the value is nil" do
      let(:value) { nil }
      it "returns false" do
        expect(acc.value?).to eq(false)
      end
    end
  end
end
