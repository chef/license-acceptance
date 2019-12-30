require "spec_helper"
require "license_acceptance/acceptor"

RSpec.describe LicenseAcceptance::Acceptor do
  it "has a version number" do
    expect(LicenseAcceptance::VERSION).not_to be nil
  end

  let(:output) do
    d = StringIO.new
    allow(d).to receive(:isatty).and_return(true)
    d
  end
  let(:opts) { { output: output } }
  let(:reader) { instance_double(LicenseAcceptance::ProductReader) }
  let(:acc) { LicenseAcceptance::Acceptor.new(opts) }
  let(:product) { instance_double(LicenseAcceptance::Product, id: "foo", pretty_name: "Foo") }
  let(:version) { "version" }
  let(:relationship) { instance_double(LicenseAcceptance::ProductRelationship, parent: product) }
  let(:missing) { [product] }

  describe "#check_and_persist!" do
    before do
      expect(LicenseAcceptance::ProductReader).to receive(:new).and_return(reader)
      expect(reader).to receive(:read)
    end

    let(:err) { LicenseAcceptance::LicenseNotAcceptedError.new(product, [product]) }
    it "outputs an error message to stdout and exits when license acceptance is declined" do
      expect(acc).to receive(:check_and_persist).and_raise(err)
      expect { acc.check_and_persist!(product.id, version) }.to raise_error(SystemExit)
      expect(output.string).to match(/#{product.pretty_name}/)
    end
  end

  describe "#check_and_persist" do
    let(:file_acc) { instance_double(LicenseAcceptance::Strategy::File) }
    let(:arg_acc) { instance_double(LicenseAcceptance::Strategy::Argument) }
    let(:prompt_acc) { instance_double(LicenseAcceptance::Strategy::Prompt) }
    let(:env_acc) { instance_double(LicenseAcceptance::Strategy::Environment) }
    let(:provided_acc) { instance_double(LicenseAcceptance::Strategy::ProvidedValue) }

    before do
      expect(LicenseAcceptance::ProductReader).to receive(:new).and_return(reader)
      expect(LicenseAcceptance::Strategy::File).to receive(:new).and_return(file_acc)
      expect(LicenseAcceptance::Strategy::Argument).to receive(:new).and_return(arg_acc)
      expect(LicenseAcceptance::Strategy::Prompt).to receive(:new).and_return(prompt_acc)
      expect(LicenseAcceptance::Strategy::Environment).to receive(:new).and_return(env_acc)
      expect(LicenseAcceptance::Strategy::ProvidedValue).to receive(:new).and_return(provided_acc)

      allow(provided_acc).to receive(:no_persist?).and_return(false)
      allow(env_acc).to receive(:no_persist?).and_return(false)
      allow(arg_acc).to receive(:no_persist?).and_return(false)
      allow(provided_acc).to receive(:accepted?).and_return(false)
      allow(env_acc).to receive(:accepted?).and_return(false)
      allow(arg_acc).to receive(:accepted?).and_return(false)
      allow(provided_acc).to receive(:silent?).and_return(false)
      allow(env_acc).to receive(:silent?).and_return(false)
      allow(arg_acc).to receive(:silent?).and_return(false)

      expect(reader).to receive(:read)
    end

    describe "when accept-no-persist is provided from the caller" do
      it "returns true" do
        expect(provided_acc).to receive(:no_persist?).and_return(true)
        expect(acc.check_and_persist(product, version)).to eq(true)
        expect(acc.acceptance_value).to eq(LicenseAcceptance::ACCEPT_NO_PERSIST)
      end
    end

    describe "when accept-no-persist environment variable is set" do
      it "returns true" do
        expect(env_acc).to receive(:no_persist?).and_return(true)
        expect(acc.check_and_persist(product, version)).to eq(true)
        expect(acc.acceptance_value).to eq(LicenseAcceptance::ACCEPT_NO_PERSIST)
      end
    end

    describe "when accept-no-persist command line argument is set" do
      it "returns true" do
        expect(arg_acc).to receive(:no_persist?).and_return(true)
        expect(acc.check_and_persist(product, version)).to eq(true)
        expect(acc.acceptance_value).to eq(LicenseAcceptance::ACCEPT_NO_PERSIST)
      end
    end

    describe "when there are no missing licenses" do
      it "returns true" do
        expect(reader).to receive(:lookup).with(product, version).and_return(relationship)
        expect(file_acc).to receive(:accepted?).with(relationship).and_return([])
        expect(acc.check_and_persist(product, version)).to eq(true)
        expect(acc.acceptance_value).to eq(LicenseAcceptance::ACCEPT)
      end
    end

    describe "when the user accepts as an environment variable" do
      it "returns true" do
        expect(reader).to receive(:lookup).with(product, version).and_return(relationship)
        expect(file_acc).to receive(:accepted?).with(relationship).and_return(missing)
        expect(env_acc).to receive(:accepted?).and_return(true)
        expect(file_acc).to receive(:persist).with(relationship, missing).and_return([])
        expect(acc.check_and_persist(product, version)).to eq(true)
        expect(output.string).to match(/1 product license accepted./)
        expect(acc.acceptance_value).to eq(LicenseAcceptance::ACCEPT)
      end

      describe "when persist is set to false" do
        let(:opts) { { output: output, persist: false } }

        it "returns true" do
          expect(reader).to receive(:lookup).with(product, version).and_return(relationship)
          expect(file_acc).to receive(:accepted?).with(relationship).and_return(missing)
          expect(env_acc).to receive(:accepted?).and_return(true)
          expect(acc.check_and_persist(product, version)).to eq(true)
          expect(output.string).to_not match(/accepted./)
          expect(acc.acceptance_value).to eq(LicenseAcceptance::ACCEPT)
        end
      end

      describe "when the silent option is used" do
        let(:opts) { { output: output } }

        it "returns true and silently persists the file" do
          expect(reader).to receive(:lookup).with(product, version).and_return(relationship)
          expect(file_acc).to receive(:accepted?).with(relationship).and_return(missing)
          expect(env_acc).to receive(:silent?).times.exactly(3).and_return(true)
          expect(file_acc).to receive(:persist).with(relationship, missing).and_return([])
          expect(acc.check_and_persist(product, version)).to eq(true)
          expect(output.string).to be_empty
          expect(acc.acceptance_value).to eq(LicenseAcceptance::ACCEPT_SILENT)
        end
      end

      describe "when file persistance fails" do
        it "returns true" do
          expect(reader).to receive(:lookup).with(product, version).and_return(relationship)
          expect(file_acc).to receive(:accepted?).with(relationship).and_return(missing)
          expect(env_acc).to receive(:accepted?).and_return(true)
          expect(file_acc).to receive(:persist).with(relationship, missing).and_return([StandardError.new("foo")])
          expect(acc.check_and_persist(product, version)).to eq(true)
          expect(output.string).to match(/Could not persist acceptance:/)
          expect(acc.acceptance_value).to eq(LicenseAcceptance::ACCEPT)
        end
      end
    end

    describe "when the user accepts as an arg" do
      it "returns true" do
        expect(reader).to receive(:lookup).with(product, version).and_return(relationship)
        expect(file_acc).to receive(:accepted?).with(relationship).and_return(missing)
        expect(arg_acc).to receive(:accepted?).and_return(true)
        expect(file_acc).to receive(:persist).with(relationship, missing).and_return([])
        expect(acc.check_and_persist(product, version)).to eq(true)
        expect(output.string).to match(/1 product license accepted./)
        expect(acc.acceptance_value).to eq(LicenseAcceptance::ACCEPT)
      end

      describe "when the silent option is used" do
        let(:opts) { { output: output } }

        it "returns true and silently persists the file" do
          expect(reader).to receive(:lookup).with(product, version).and_return(relationship)
          expect(file_acc).to receive(:accepted?).with(relationship).and_return(missing)
          expect(arg_acc).to receive(:silent?).times.exactly(3).and_return(true)
          expect(file_acc).to receive(:persist).with(relationship, missing).and_return([])
          expect(acc.check_and_persist(product, version)).to eq(true)
          expect(output.string).to be_empty
          expect(acc.acceptance_value).to eq(LicenseAcceptance::ACCEPT_SILENT)
        end
      end

      describe "when persist is set to false" do
        let(:opts) { { output: output, persist: false } }

        it "returns true" do
          expect(reader).to receive(:lookup).with(product, version).and_return(relationship)
          expect(file_acc).to receive(:accepted?).with(relationship).and_return(missing)
          expect(arg_acc).to receive(:accepted?).and_return(true)
          expect(acc.check_and_persist(product, version)).to eq(true)
          expect(output.string).to_not match(/accepted./)
          expect(acc.acceptance_value).to eq(LicenseAcceptance::ACCEPT)
        end
      end

      describe "when file persistance fails" do
        it "returns true" do
          expect(reader).to receive(:lookup).with(product, version).and_return(relationship)
          expect(file_acc).to receive(:accepted?).with(relationship).and_return(missing)
          expect(arg_acc).to receive(:accepted?).and_return(true)
          expect(file_acc).to receive(:persist).with(relationship, missing).and_return([StandardError.new("bar")])
          expect(acc.check_and_persist(product, version)).to eq(true)
          expect(output.string).to match(/Could not persist acceptance:/)
          expect(acc.acceptance_value).to eq(LicenseAcceptance::ACCEPT)
        end
      end
    end

    describe "when the prompt is not a tty" do
      let(:opts) { { output: File.open(File::NULL, "w") } }
      it "raises a LicenseNotAcceptedError error" do
        expect(reader).to receive(:lookup).with(product, version).and_return(relationship)
        expect(file_acc).to receive(:accepted?).with(relationship).and_return(missing)
        expect(prompt_acc).to_not receive(:request)
        expect { acc.check_and_persist(product, version) }.to raise_error(LicenseAcceptance::LicenseNotAcceptedError)
        expect(acc.acceptance_value).to eq(nil)
      end
    end

    describe "when the user accepts with the prompt" do
      it "returns true" do
        expect(reader).to receive(:lookup).with(product, version).and_return(relationship)
        expect(file_acc).to receive(:accepted?).with(relationship).and_return(missing)
        expect(prompt_acc).to receive(:request).with(missing).and_yield.and_return(true)
        expect(file_acc).to receive(:persist).with(relationship, missing)
        expect(acc.check_and_persist(product, version)).to eq(true)
        expect(acc.acceptance_value).to eq(LicenseAcceptance::ACCEPT)
      end

      describe "when persist is set to false" do
        let(:opts) { { output: output, persist: false } }

        it "returns true" do
          expect(reader).to receive(:lookup).with(product, version).and_return(relationship)
          expect(file_acc).to receive(:accepted?).with(relationship).and_return(missing)
          expect(prompt_acc).to receive(:request).with(missing).and_yield.and_return(true)
          expect(acc.check_and_persist(product, version)).to eq(true)
          expect(acc.acceptance_value).to eq(LicenseAcceptance::ACCEPT_NO_PERSIST)
        end
      end
    end

    describe "when the user declines with the prompt" do
      it "raises a LicenseNotAcceptedError error" do
        expect(reader).to receive(:lookup).with(product, version).and_return(relationship)
        expect(file_acc).to receive(:accepted?).with(relationship).and_return(missing)
        expect(prompt_acc).to receive(:request).with(missing).and_return(false)
        expect { acc.check_and_persist(product, version) }.to raise_error(LicenseAcceptance::LicenseNotAcceptedError)
        expect(acc.acceptance_value).to eq(nil)
      end
    end
  end

  describe "#license_required?" do
    let(:reader) { instance_double(LicenseAcceptance::ProductReader) }
    let(:mixlib_name) { "chef" }
    let(:version) { "15.0.0" }
    let(:product) { instance_double(LicenseAcceptance::Product, id: "foo", license_required_version: "15.0.0") }

    before do
      expect(LicenseAcceptance::ProductReader).to receive(:new).and_return(reader)
      expect(reader).to receive(:read)
    end

    it "returns false if no product can be found" do
      expect(reader).to receive(:lookup_by_mixlib).with(mixlib_name).and_return nil
      expect(acc.license_required?(mixlib_name, version)).to eq(false)
    end

    describe "when version is :latest" do
      let(:version) { :latest }
      it "returns true" do
        expect(reader).to receive(:lookup_by_mixlib).with(mixlib_name).and_return product
        expect(acc.license_required?(mixlib_name, version)).to eq(true)
      end
    end

    %w{latest unstable current stable}.each do |version|
      describe "when version is '#{version}'" do
        it "returns true" do
          expect(reader).to receive(:lookup_by_mixlib).with(mixlib_name).and_return product
          expect(acc.license_required?(mixlib_name, version)).to eq(true)
        end
      end
    end

    describe "when version is nil" do
      let(:version) { nil }
      it "returns true" do
        expect(reader).to receive(:lookup_by_mixlib).with(mixlib_name).and_return product
        expect(acc.license_required?(mixlib_name, version)).to eq(true)
      end
    end

    describe "when version is >= than required version" do
      let(:version) { "15.0.0" }
      it "returns true" do
        expect(reader).to receive(:lookup_by_mixlib).with(mixlib_name).and_return product
        expect(acc.license_required?(mixlib_name, version)).to eq(true)
      end
    end

    describe "when version is < required version" do
      let(:version) { "14.99.99" }
      it "returns false" do
        expect(reader).to receive(:lookup_by_mixlib).with(mixlib_name).and_return product
        expect(acc.license_required?(mixlib_name, version)).to eq(false)
      end
    end
  end
end
