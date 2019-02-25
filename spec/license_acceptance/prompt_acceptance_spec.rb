require "spec_helper"
require "license_acceptance/prompt_acceptance"
require "license_acceptance/product"
require "tty-prompt"

RSpec.describe LicenseAcceptance::PromptAcceptance do
  let(:klass) { LicenseAcceptance::PromptAcceptance }
  let(:prompt) { instance_double(TTY::Prompt) }
  let(:p1) { instance_double(LicenseAcceptance::Product, pretty_name: "Pretty Name") }
  let(:missing_licenses) { [p1] }
  let(:output) { StringIO.new }

  before do
    expect(TTY::Prompt).to receive(:new).at_least(:once).and_return(prompt)
  end

  describe "when the user accepts" do
    it "returns true" do
      expect(prompt).to receive(:ask).and_return("yes")
      msg1 = /License that need accepting:\n  \* #{p1.pretty_name}/m
      msg2 = /product license accepted\./
      r = nil
      expect { |b| r = klass.request(missing_licenses, output, &b) }.to yield_control
      expect(output.string).to match(msg1)
      expect(output.string).to match(msg2)
      expect(r).to eq(true)
    end

    describe "when there are multiple products" do
      let(:p2) { instance_double(LicenseAcceptance::Product, pretty_name: "Other") }
      let(:missing_licenses) { [p1, p2] }
      it "returns true" do
        expect(prompt).to receive(:ask).and_return("yes")
        msg1 = /Licenses that need accepting:\n  \* #{p1.pretty_name}\n  \* #{p2.pretty_name}/m
        msg2 = /product licenses accepted\./
        msg3 = /2 product licenses\nmust be accepted/m
        r = nil
        expect { |b| r = klass.request(missing_licenses, output, &b) }.to yield_control
        expect(output.string).to match(msg1)
        expect(output.string).to match(msg2)
        expect(output.string).to match(msg3)
        expect(r).to eq(true)
      end
    end
  end

  describe "when the user declines twice" do
    it "returns false" do
      expect(prompt).to receive(:ask).twice.and_return("no")
      msg1 = /License that need accepting:\n  \* #{p1.pretty_name}/m
      msg2 = /product license accepted\./
      r = nil
      expect { |b| r = klass.request(missing_licenses, output, &b) }.to_not yield_control
      expect(output.string).to match(msg1)
      expect(output.string).to_not match(msg2)
      expect(r).to eq(false)
    end
  end

  describe "when the user declines once then accepts" do
    it "returns true" do
      expect(prompt).to receive(:ask).and_return("no")
      expect(prompt).to receive(:ask).and_return("yes")
      msg1 = /License that need accepting:\n  \* #{p1.pretty_name}/m
      msg2 = /product license accepted\./
      msg3 = /If you do not accept this license you will\nnot be able to use Chef products/m
      r = nil
      expect { |b| r = klass.request(missing_licenses, output, &b) }.to yield_control
      expect(output.string).to match(msg1)
      expect(output.string).to match(msg2)
      expect(output.string).to match(msg3)
      expect(r).to eq(true)
    end
  end

end
