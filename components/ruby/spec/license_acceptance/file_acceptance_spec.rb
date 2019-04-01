require "spec_helper"
require "license_acceptance/config"
require "license_acceptance/file_acceptance"
require "license_acceptance/product_relationship"
require "license_acceptance/product"

RSpec.describe LicenseAcceptance::FileAcceptance do
  let(:dir1) { "/dir1" }
  let(:dir2) { "/dir2" }
  let(:dir3) { "/dir3" }
  let(:config) do
    instance_double(LicenseAcceptance::Config, license_locations: [dir1, dir2], persist_location: dir3)
  end
  let(:acc) { LicenseAcceptance::FileAcceptance.new(config) }
  let(:p1_name) { "chef_client" }
  let(:p1_filename) { "p1_filename" }
  let(:p1) { instance_double(LicenseAcceptance::Product, name: p1_name, filename: p1_filename) }
  let(:version) { "0.1.0" }
  let(:product_relationship) { instance_double(LicenseAcceptance::ProductRelationship, parent: p1, children: [], parent_version: version) }

  describe "#check" do
    describe "when there is an existing license file" do
      it "returns an empty missing product list" do
        expect(File).to receive(:exist?).with(File.join(dir1, p1_filename)).and_return(true)
        expect(acc.check(product_relationship)).to eq([])
      end
    end

    describe "when there is not an existing license file" do
      it "returns the product in the missing product list" do
        expect(File).to receive(:exist?).with(File.join(dir1, p1_filename)).and_return(false)
        expect(File).to receive(:exist?).with(File.join(dir2, p1_filename)).and_return(false)
        expect(acc.check(product_relationship)).to eq([p1])
      end
    end

    describe "#persist" do
      let(:file) { double("file") }

      before do
        expect(Dir).to receive(:exist?).with(dir3).at_least(:once).and_return(true)
      end

      it "stores a single license without children" do
        expect(File).to receive(:open).with(File.join(dir3, p1_filename), "w").and_yield(file)
        expect(file).to receive(:<<) do |yaml|
          yaml = YAML.load(yaml)
          expect(yaml["name"]).to eq(p1_name)
          expect(yaml["accepting_product"]).to eq(p1_name)
          expect(yaml["accepting_product_version"]).to eq(version)
        end
        acc.persist(product_relationship, [p1])
      end

      describe "when license has children" do
        let(:p2_name) { "inspec" }
        let(:p2_filename) { "p2_filename" }
        let(:p2) { instance_double(LicenseAcceptance::Product, name: p2_name, filename: p2_filename) }
        let(:product_relationship) {
          instance_double(
            LicenseAcceptance::ProductRelationship,
            parent: p1,
            children: [p2],
            parent_version: version
          )
        }

        it "stores a license file for all" do
          expect(File).to receive(:open).with(File.join(dir3, p1_filename), "w").and_yield(file)
          expect(file).to receive(:<<) do |yaml|
            yaml = YAML.load(yaml)
            expect(yaml["name"]).to eq(p1_name)
            expect(yaml["accepting_product"]).to eq(p1_name)
            expect(yaml["accepting_product_version"]).to eq(version)
          end
          expect(File).to receive(:open).with(File.join(dir3, p2_filename), "w").and_yield(file)
          expect(file).to receive(:<<) do |yaml|
            yaml = YAML.load(yaml)
            expect(yaml["name"]).to eq(p2_name)
            expect(yaml["accepting_product"]).to eq(p1_name)
            expect(yaml["accepting_product_version"]).to eq(version)
          end
          acc.persist(product_relationship, [p1, p2])
        end

        describe "when parent is already persisted" do
          it "only stores a license file for the child" do
            expect(File).to receive(:open).once.with(File.join(dir3, p2_filename), "w").and_yield(file)
            expect(file).to receive(:<<) do |yaml|
              yaml = YAML.load(yaml)
              expect(yaml["name"]).to eq(p2_name)
              expect(yaml["accepting_product"]).to eq(p1_name)
              expect(yaml["accepting_product_version"]).to eq(version)
            end
            acc.persist(product_relationship, [p2])
          end
        end
      end
    end

  end
end
