require "spec_helper"
require "license_acceptance/strategy/prompt"
require "license_acceptance/product"
require "tty-prompt"

RSpec.describe LicenseAcceptance::Strategy::Prompt do
  let(:output) { StringIO.new }
  let(:config) do
    instance_double(LicenseAcceptance::Config, output: output)
  end
  let(:acc) { LicenseAcceptance::Strategy::Prompt.new(config) }
  let(:prompt) { instance_double(TTY::Prompt) }
  let(:p1) { instance_double(LicenseAcceptance::Product, name: "name", pretty_name: "Pretty Name") }
  let(:missing_licenses) { [p1] }

  before do
    expect(TTY::Prompt).to receive(:new).at_least(:once).and_return(prompt)
  end

  describe "when the user accepts" do
    it "returns true" do
      expect(prompt).to receive(:ask).and_return("yes")
      msg1 = /License that need accepting:\n  \* #{p1.pretty_name}/m
      msg2 = /product license persisted\./
      b = Proc.new { [] }
      expect(acc.request(missing_licenses, &b)).to eq(true)
      expect(output.string).to match(msg1)
      expect(output.string).to match(msg2)
    end

    describe "when there are multiple products" do
      let(:p2) { instance_double(LicenseAcceptance::Product, name: "other_name", pretty_name: "Other") }
      let(:missing_licenses) { [p1, p2] }
      it "returns true" do
        expect(prompt).to receive(:ask).and_return("yes")
        msg1 = /Licenses that need accepting:\n  \* #{p1.pretty_name}\n  \* #{p2.pretty_name}/m
        msg2 = /product licenses persisted\./
        msg3 = /2 product licenses\nmust be accepted/m
        b = Proc.new { [] }
        expect(acc.request(missing_licenses, &b)).to eq(true)
        expect(output.string).to match(msg1)
        expect(output.string).to match(msg2)
        expect(output.string).to match(msg3)
      end
    end

    describe "when the callback returns an error" do
      it "returns true" do
        expect(prompt).to receive(:ask).and_return("yes")
        msg1 = /License that need accepting:\n  \* #{p1.pretty_name}/m
        msg2 = /Could not persist acceptance:/
        b = Proc.new { [StandardError.new("foo")] }
        expect(acc.request(missing_licenses, &b)).to eq(true)
        expect(output.string).to match(msg1)
        expect(output.string).to match(msg2)
      end
    end
  end

  describe "when the prompt times out" do
    it "returns false" do
      expect(Timeout).to receive(:timeout).twice.and_yield
      expect(prompt).to receive(:ask).twice.and_raise(LicenseAcceptance::Strategy::PromptTimeout)
      expect(prompt).to receive(:unsubscribe).twice
      expect(prompt).to receive(:reader).twice
      msg1 = /Prompt timed out./
      b = Proc.new { [] }
      expect(acc.request(missing_licenses, &b)).to eq(false)
      expect(output.string).to match(msg1)
    end
  end

  describe "when the user declines twice" do
    it "returns false" do
      expect(prompt).to receive(:ask).twice.and_return("no")
      msg1 = /License that need accepting:\n  \* #{p1.pretty_name}/m
      msg2 = /product license persisted\./
      b = Proc.new { raise "should not be called" }
      expect(acc.request(missing_licenses, &b)).to eq(false)
      expect(output.string).to match(msg1)
      expect(output.string).to_not match(msg2)
    end
  end

  describe "when the user declines once then accepts" do
    it "returns true" do
      expect(prompt).to receive(:ask).and_return("no")
      expect(prompt).to receive(:ask).and_return("yes")
      msg1 = /License that need accepting:\n  \* #{p1.pretty_name}/m
      msg2 = /product license persisted\./
      msg3 = /If you do not accept this license you will\nnot be able to use Chef products/m
      b = Proc.new { [] }
      expect(acc.request(missing_licenses, &b)).to eq(true)
      expect(output.string).to match(msg1)
      expect(output.string).to match(msg2)
      expect(output.string).to match(msg3)
    end
  end

end
