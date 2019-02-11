require "spec_helper"
require "license_acceptance/acceptor"

RSpec.describe LicenseAcceptance::Acceptor do
  it "has a version number" do
    expect(LicenseAcceptance::VERSION).not_to be nil
  end

  let(:klass) { LicenseAcceptance::Acceptor }
  let(:product) { "chef" }
  let(:version) { "version" }
  let(:relationship) { instance_double(LicenseAcceptance::ProductRelationship) }
  let(:p1) { instance_double(LicenseAcceptance::Product) }
  let(:missing) { [p1] }

  describe "#check_and_persist!" do
    let(:err) { LicenseAcceptance::LicenseNotAcceptedError.new([product]) }
    it "outputs an error message to stdout and exits when license acceptance is declined" do
      expect(klass).to receive(:check_and_persist).and_raise(err)
      expect { klass.check_and_persist!(product, version) }.to output(/#{product}/).to_stdout.and raise_error(SystemExit)
    end

    describe "when output is not stdout" do
      let(:out) { StringIO.new }
      it "outputs an error message and exits when license acceptance is declined" do
        expect(klass).to receive(:check_and_persist).and_raise(err)
        expect { klass.check_and_persist!(product, version, out) }.to raise_error(SystemExit)
        expect(out.string).to match(/#{product}/)
      end
    end
  end

  describe "#check_and_persist" do
    describe "when test environment variable is set" do
      before do
        ENV['ACCEPT_CHEF_LICENSE_NO_PERSIST'] = 'true'
      end

      after do
        ENV.delete('ACCEPT_CHEF_LICENSE_NO_PERSIST')
      end

      it "returns true" do
        expect(LicenseAcceptance::ProductRelationship).to_not receive(:lookup)
        expect(LicenseAcceptance::FileAcceptance).to_not receive(:check)
        expect(LicenseAcceptance::ArgAcceptance).to_not receive(:check)
        expect(LicenseAcceptance::FileAcceptance).to_not receive(:persist)
        expect(LicenseAcceptance::PromptAcceptance).to_not receive(:request)
        expect(klass.check_and_persist(product, version)).to eq(true)
      end
    end

    describe "when there are no missing licenses" do
      it "returns true" do
        expect(LicenseAcceptance::ProductRelationship).to receive(:lookup).with(product, version)
          .and_return(relationship)
        expect(LicenseAcceptance::FileAcceptance).to receive(:check).with(relationship).and_return([])
        expect(LicenseAcceptance::ArgAcceptance).to_not receive(:check)
        expect(LicenseAcceptance::FileAcceptance).to_not receive(:persist)
        expect(LicenseAcceptance::PromptAcceptance).to_not receive(:request)
        expect(klass.check_and_persist(product, version)).to eq(true)
      end
    end

    describe "when the user accepts as an arg" do
      it "returns true" do
        expect(LicenseAcceptance::ProductRelationship).to receive(:lookup).with(product, version)
          .and_return(relationship)
        expect(LicenseAcceptance::FileAcceptance).to receive(:check).with(relationship).and_return(missing)
        expect(LicenseAcceptance::ArgAcceptance).to receive(:check).with(ARGV).and_yield.and_return(true)
        expect(LicenseAcceptance::FileAcceptance).to receive(:persist).with(relationship, missing)
        expect(LicenseAcceptance::PromptAcceptance).to_not receive(:request)
        expect(klass.check_and_persist(product, version)).to eq(true)
      end
    end

    describe "when the user accepts with the prompt" do
      it "returns true" do
        expect(LicenseAcceptance::ProductRelationship).to receive(:lookup).with(product, version)
          .and_return(relationship)
        expect(LicenseAcceptance::FileAcceptance).to receive(:check).with(relationship).and_return(missing)
        expect(LicenseAcceptance::ArgAcceptance).to receive(:check).and_return(false)
        expect(LicenseAcceptance::PromptAcceptance).to receive(:request).with(missing, STDOUT).and_yield.and_return(true)
        expect(LicenseAcceptance::FileAcceptance).to receive(:persist).with(relationship, missing)
        expect(klass.check_and_persist(product, version)).to eq(true)
      end
    end

    describe "when the user accepts with the prompt" do
      it "returns true" do
        expect(LicenseAcceptance::ProductRelationship).to receive(:lookup).with(product, version)
          .and_return(relationship)
        expect(LicenseAcceptance::FileAcceptance).to receive(:check).with(relationship).and_return(missing)
        expect(LicenseAcceptance::ArgAcceptance).to receive(:check).and_return(false)
        expect(LicenseAcceptance::PromptAcceptance).to receive(:request).with(missing, STDOUT).and_return(false)
        expect { klass.check_and_persist(product, version) }.to raise_error(LicenseAcceptance::LicenseNotAcceptedError)
      end
    end

  end
end
