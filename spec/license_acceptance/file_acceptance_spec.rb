require "spec_helper"
require "license_acceptance/file_acceptance"
require "license_acceptance/product_relationship"
require "license_acceptance/product"

RSpec.describe LicenseAcceptance::FileAcceptance do
  let(:klass) { LicenseAcceptance::FileAcceptance }
  let(:license_dir) { File.join(ENV['HOME'], '.chef', 'accepted_licenses') }
  let(:p1_name) { "chef_client" }
  let(:p1) { instance_double(LicenseAcceptance::Product, name: p1_name) }
  let(:version) { "0.1.0" }
  let(:product_relationship) { instance_double(LicenseAcceptance::ProductRelationship, parent: p1, children: [], parent_version: version) }

  describe "#check" do
    describe "when there is an existing license file" do
      it "returns an empty missing product list" do
        expect(File).to receive(:exist?).with(File.join(license_dir, p1_name)).and_return(true)
        expect(klass.check(product_relationship)).to eq([])
      end
    end

    describe "when there is not an existing license file" do
      it "returns the product in the missing product list" do
        expect(File).to receive(:exist?).with(File.join(license_dir, p1_name)).and_return(false)
        expect(File).to receive(:exist?).with(File.join("/etc/chef/accepted_licenses", p1_name)).and_return(false)
        expect(klass.check(product_relationship)).to eq([p1])
      end
    end

    describe "#persist" do
      let(:file) { double("file") }
      it "stores a single license without children" do
        expect(File).to receive(:open).with(File.join(license_dir, p1_name), "w").and_yield(file)
        expect(file).to receive(:<<) do |yaml|
          yaml = YAML.load(yaml)
          expect(yaml["name"]).to eq(p1_name)
          expect(yaml["accepting_product"]).to eq(p1_name)
          expect(yaml["accepting_product_version"]).to eq(version)
        end
        klass.persist(product_relationship, [p1])
      end

      describe "when license has children" do
        let(:p2_name) { "inspec" }
        let(:p2) { instance_double(LicenseAcceptance::Product, name: p2_name) }
        let(:product_relationship) {
          instance_double(
            LicenseAcceptance::ProductRelationship,
            parent: p1,
            children: [p2],
            parent_version: version
          )
        }

        it "stores a license file for all" do
          expect(File).to receive(:open).with(File.join(license_dir, p1_name), "w").and_yield(file)
          expect(file).to receive(:<<) do |yaml|
            yaml = YAML.load(yaml)
            expect(yaml["name"]).to eq(p1_name)
            expect(yaml["accepting_product"]).to eq(p1_name)
            expect(yaml["accepting_product_version"]).to eq(version)
          end
          expect(File).to receive(:open).with(File.join(license_dir, p2_name), "w").and_yield(file)
          expect(file).to receive(:<<) do |yaml|
            yaml = YAML.load(yaml)
            expect(yaml["name"]).to eq(p2_name)
            expect(yaml["accepting_product"]).to eq(p1_name)
            expect(yaml["accepting_product_version"]).to eq(version)
          end
          klass.persist(product_relationship, [p1, p2])
        end

        describe "when parent is already persisted" do
          it "only stores a license file for the child" do
            expect(File).to receive(:open).once.with(File.join(license_dir, p2_name), "w").and_yield(file)
            expect(file).to receive(:<<) do |yaml|
              yaml = YAML.load(yaml)
              expect(yaml["name"]).to eq(p2_name)
              expect(yaml["accepting_product"]).to eq(p1_name)
              expect(yaml["accepting_product_version"]).to eq(version)
            end
            klass.persist(product_relationship, [p2])
          end
        end
      end
    end

  end
end
