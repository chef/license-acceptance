require "spec_helper"
require "license_acceptance/file_acceptance"
require "license_acceptance/product_set"

RSpec.describe LicenseAcceptance::FileAcceptance do
  let(:klass) { LicenseAcceptance::FileAcceptance }
  let(:license_dir) { File.join(ENV['HOME'], '.chef', 'accepted_licenses') }
  let(:product) { "chef" }
  let(:version) { "0.1.0" }
  let(:product_set) { instance_double(LicenseAcceptance::ProductSet, parent: product, children: [], parent_version: version) }

  describe "::check" do
    describe "when there is an existing license file" do
      it "returns an empty missing product list" do
        expect(File).to receive(:exist?).with(File.join(license_dir, product)).and_return(true)
        expect(klass.check(product_set)).to eq([])
      end
    end

    describe "when there is not an existing license file" do
      it "returns the product in the missing product list" do
        expect(File).to receive(:exist?).with(File.join(license_dir, product)).and_return(false)
        expect(File).to receive(:exist?).with(File.join("/etc/chef/accepted_licenses", product)).and_return(false)
        expect(klass.check(product_set)).to eq([product])
      end
    end

    describe "::persist" do
      let(:file) { double("file") }
      it "stores a single license without children" do
        expect(File).to receive(:open).with(File.join(license_dir, product), "w").and_yield(file)
        expect(file).to receive(:<<) do |yaml|
          yaml = YAML.load(yaml)
          expect(yaml["name"]).to eq(product)
          expect(yaml["accepting_product"]).to eq(product)
          expect(yaml["accepting_product_version"]).to eq(version)
        end
        klass.persist(product_set, [product])
      end

      describe "when license has children" do
        let(:child) { "inspec" }
        let(:product_set) {
          instance_double(
            LicenseAcceptance::ProductSet,
            parent: product,
            children: [child],
            parent_version: version
          )
        }

        it "stores a license file for all" do
          expect(File).to receive(:open).with(File.join(license_dir, product), "w").and_yield(file)
          expect(file).to receive(:<<) do |yaml|
            yaml = YAML.load(yaml)
            expect(yaml["name"]).to eq(product)
            expect(yaml["accepting_product"]).to eq(product)
            expect(yaml["accepting_product_version"]).to eq(version)
          end
          expect(File).to receive(:open).with(File.join(license_dir, child), "w").and_yield(file)
          expect(file).to receive(:<<) do |yaml|
            yaml = YAML.load(yaml)
            expect(yaml["name"]).to eq(child)
            expect(yaml["accepting_product"]).to eq(product)
            expect(yaml["accepting_product_version"]).to eq(version)
          end
          klass.persist(product_set, [product, child])
        end

        describe "when parent is already persisted" do
          it "only stores a license file for the child" do
            expect(File).to receive(:open).once.with(File.join(license_dir, child), "w").and_yield(file)
            expect(file).to receive(:<<) do |yaml|
              yaml = YAML.load(yaml)
              expect(yaml["name"]).to eq(child)
              expect(yaml["accepting_product"]).to eq(product)
              expect(yaml["accepting_product_version"]).to eq(version)
            end
            klass.persist(product_set, [child])
          end
        end
      end
    end

  end
end
