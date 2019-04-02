require "spec_helper"
require "license_acceptance/acceptor"

RSpec.describe LicenseAcceptance::Acceptor do
  it "has a version number" do
    expect(LicenseAcceptance::VERSION).not_to be nil
  end

  let(:output) { StringIO.new }
  let(:opts) { { output: output } }
  let(:acc) { LicenseAcceptance::Acceptor.new(opts) }
  let(:product) { "chef_client" }
  let(:version) { "version" }
  let(:relationship) { instance_double(LicenseAcceptance::ProductRelationship) }
  let(:p1) { instance_double(LicenseAcceptance::Product) }
  let(:missing) { [p1] }

  describe "#check_and_persist!" do
    let(:err) { LicenseAcceptance::LicenseNotAcceptedError.new([product]) }
    it "outputs an error message to stdout and exits when license acceptance is declined" do
      expect(acc).to receive(:check_and_persist).and_raise(err)
      expect { acc.check_and_persist!(product, version) }.to raise_error(SystemExit)
      expect(output.string).to match(/#{product}/)
    end
  end

  describe "#check_and_persist" do
    let(:reader) { instance_double(LicenseAcceptance::ProductReader) }
    let(:file_acc) { instance_double(LicenseAcceptance::FileAcceptance) }
    let(:arg_acc) { instance_double(LicenseAcceptance::ArgAcceptance) }
    let(:prompt_acc) { instance_double(LicenseAcceptance::PromptAcceptance) }
    let(:env_acc) { instance_double(LicenseAcceptance::EnvAcceptance) }

    before do
      expect(LicenseAcceptance::ProductReader).to receive(:new).and_return(reader)
      expect(LicenseAcceptance::FileAcceptance).to receive(:new).and_return(file_acc)
      expect(LicenseAcceptance::ArgAcceptance).to receive(:new).and_return(arg_acc)
      expect(LicenseAcceptance::PromptAcceptance).to receive(:new).and_return(prompt_acc)
      expect(LicenseAcceptance::EnvAcceptance).to receive(:new).and_return(env_acc)
    end

    describe "when check-no-persist environment variable is set" do
      it "returns true" do
        expect(env_acc).to receive(:check_no_persist).and_return(true)
        expect(acc.check_and_persist(product, version)).to eq(true)
      end
    end

    describe "when check-no-persist command line argument is set" do
      it "returns true" do
        expect(env_acc).to receive(:check_no_persist).and_return(false)
        expect(arg_acc).to receive(:check_no_persist).and_return(true)
        expect(acc.check_and_persist(product, version)).to eq(true)
      end
    end

    describe "when there are no missing licenses" do
      it "returns true" do
        expect(env_acc).to receive(:check_no_persist).and_return(false)
        expect(arg_acc).to receive(:check_no_persist).and_return(false)
        expect(reader).to receive(:read)
        expect(reader).to receive(:lookup).with(product, version).and_return(relationship)
        expect(file_acc).to receive(:check).with(relationship).and_return([])
        expect(acc.check_and_persist(product, version)).to eq(true)
      end
    end

    describe "when the user accepts as an environment variable" do
      it "returns true" do
        expect(env_acc).to receive(:check_no_persist).and_return(false)
        expect(arg_acc).to receive(:check_no_persist).and_return(false)
        expect(reader).to receive(:read)
        expect(reader).to receive(:lookup).with(product, version).and_return(relationship)
        expect(file_acc).to receive(:check).with(relationship).and_return(missing)
        expect(env_acc).to receive(:check).with(ENV).and_return(true)
        expect(file_acc).to receive(:persist).with(relationship, missing)
        expect(acc.check_and_persist(product, version)).to eq(true)
        expect(output.string).to match(/1 product license accepted./)
      end

      describe "when persist is set to false" do
        let(:opts) { { output: output, persist: false } }

        it "returns true" do
          expect(env_acc).to receive(:check_no_persist).and_return(false)
          expect(arg_acc).to receive(:check_no_persist).and_return(false)
          expect(reader).to receive(:read)
          expect(reader).to receive(:lookup).with(product, version).and_return(relationship)
          expect(file_acc).to receive(:check).with(relationship).and_return(missing)
          expect(env_acc).to receive(:check).with(ENV).and_return(true)
          expect(acc.check_and_persist(product, version)).to eq(true)
          expect(output.string).to_not match(/accepted./)
        end
      end
    end

    describe "when the user accepts as an arg" do
      it "returns true" do
        expect(env_acc).to receive(:check_no_persist).and_return(false)
        expect(arg_acc).to receive(:check_no_persist).and_return(false)
        expect(reader).to receive(:read)
        expect(reader).to receive(:lookup).with(product, version).and_return(relationship)
        expect(file_acc).to receive(:check).with(relationship).and_return(missing)
        expect(env_acc).to receive(:check).and_return(false)
        expect(arg_acc).to receive(:check).with(ARGV).and_return(true)
        expect(file_acc).to receive(:persist).with(relationship, missing)
        expect(acc.check_and_persist(product, version)).to eq(true)
        expect(output.string).to match(/1 product license accepted./)
      end

      describe "when persist is set to false" do
        let(:opts) { { output: output, persist: false } }

        it "returns true" do
          expect(env_acc).to receive(:check_no_persist).and_return(false)
          expect(arg_acc).to receive(:check_no_persist).and_return(false)
          expect(reader).to receive(:read)
          expect(reader).to receive(:lookup).with(product, version).and_return(relationship)
          expect(file_acc).to receive(:check).with(relationship).and_return(missing)
          expect(env_acc).to receive(:check).and_return(false)
          expect(arg_acc).to receive(:check).with(ARGV).and_return(true)
          expect(acc.check_and_persist(product, version)).to eq(true)
          expect(output.string).to_not match(/accepted./)
        end
      end
    end

    describe "when the user accepts with the prompt" do
      it "returns true" do
        expect(env_acc).to receive(:check_no_persist).and_return(false)
        expect(arg_acc).to receive(:check_no_persist).and_return(false)
        expect(reader).to receive(:read)
        expect(reader).to receive(:lookup).with(product, version).and_return(relationship)
        expect(file_acc).to receive(:check).with(relationship).and_return(missing)
        expect(env_acc).to receive(:check).and_return(false)
        expect(arg_acc).to receive(:check).and_return(false)
        expect(prompt_acc).to receive(:request).with(missing).and_yield.and_return(true)
        expect(file_acc).to receive(:persist).with(relationship, missing)
        expect(acc.check_and_persist(product, version)).to eq(true)
      end

      describe "when persist is set to false" do
        let(:opts) { { output: output, persist: false } }

        it "returns true" do
          expect(env_acc).to receive(:check_no_persist).and_return(false)
          expect(arg_acc).to receive(:check_no_persist).and_return(false)
          expect(reader).to receive(:read)
          expect(reader).to receive(:lookup).with(product, version).and_return(relationship)
          expect(file_acc).to receive(:check).with(relationship).and_return(missing)
          expect(env_acc).to receive(:check).and_return(false)
          expect(arg_acc).to receive(:check).and_return(false)
          expect(prompt_acc).to receive(:request).with(missing).and_yield.and_return(true)
          expect(acc.check_and_persist(product, version)).to eq(true)
        end
      end
    end

    describe "when the user declines with the prompt" do
      it "returns true" do
        expect(env_acc).to receive(:check_no_persist).and_return(false)
        expect(arg_acc).to receive(:check_no_persist).and_return(false)
        expect(reader).to receive(:read)
        expect(reader).to receive(:lookup).with(product, version).and_return(relationship)
        expect(file_acc).to receive(:check).with(relationship).and_return(missing)
        expect(env_acc).to receive(:check).and_return(false)
        expect(arg_acc).to receive(:check).and_return(false)
        expect(prompt_acc).to receive(:request).with(missing).and_return(false)
        expect { acc.check_and_persist(product, version) }.to raise_error(LicenseAcceptance::LicenseNotAcceptedError)
      end
    end

  end
end
