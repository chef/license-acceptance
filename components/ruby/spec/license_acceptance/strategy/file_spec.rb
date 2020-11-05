require "spec_helper"
require "license_acceptance/config"
require "license_acceptance/strategy/file"
require "license_acceptance/product_relationship"
require "license_acceptance/product"

RSpec.describe LicenseAcceptance::Strategy::File do
  let(:dir1) { "/dir1" }
  let(:dir2) { "/dir2" }
  let(:dir3) { "/dir3" }
  let(:config) do
    instance_double(LicenseAcceptance::Config, license_locations: [dir1, dir2], persist_location: dir3)
  end
  let(:acc) { LicenseAcceptance::Strategy::File.new(config) }
  let(:p1_id) { "foo" }
  let(:p1_filename) { "p1_filename" }
  let(:p1_pretty) { "Pretty Name" }
  let(:l1) { LicenseAcceptance::License.new("FOO", "http://foo") }
  let(:p1) { instance_double(LicenseAcceptance::Product, id: p1_id, filename: p1_filename, pretty_name: p1_pretty, license: l1) }
  let(:version) { "0.1.0" }
  let(:product_relationship) { instance_double(LicenseAcceptance::ProductRelationship, parent: p1, children: [], parent_version: version) }
  let(:mode) { File::WRONLY | File::CREAT | File::TRUNC }
  let(:file) { double("file") }
  let(:license_file_contents) do
    <<~EOT
---
id: chef-workstation
name: Chef Workstation
date_accepted: '2020-10-29T16:59:07-04:00'
accepting_product: chef-workstation
accepting_product_version: '1337'
user: chefuser
file_format: 1
#{license_name_yaml}
    EOT
  end

  describe "#check" do
    describe "when there is an existing license file" do
      let(:yaml) { YAML.load(license_file_contents) }

      before do
        expect(File).to receive(:exist?).with(File.join(dir1, p1_filename)).and_return(true)
        expect(YAML).to receive(:load_file).with(File.join(dir1, p1_filename)).and_return(yaml)
        expect(File).to receive(:exist?).with(File.join(dir2, p1_filename)).and_return(false)
      end

      describe "with an explicit license" do
        describe "when the named license matches the product" do
          let(:license_name_yaml) { "license_name: FOO" }
          it "returns an empty missing product list" do
            expect(acc.accepted?(product_relationship)).to eq([])
          end
        end

        describe "when the named license does not match the product" do
          let(:license_name_yaml) { "license_name: BAR" }
          it "returns the product in the missing product list" do
            expect(acc.accepted?(product_relationship)).to eq([p1])
          end
        end
      end

      describe "with no named license" do
        # This implies that the license is the EULA
        let(:license_name_yaml) { "" }
        describe "when the product requires the EULA" do
          let(:eula_lic) { LicenseAcceptance::License.new("EULA", "http://eula") }
          let(:eula_prod) { instance_double(LicenseAcceptance::Product, id: "eula_prod", filename: p1_filename, pretty_name: "EULA Product", license: eula_lic) }
          let(:eula_relationship) { instance_double(LicenseAcceptance::ProductRelationship, parent: eula_prod, children: [], parent_version: version) }

          it "returns an empty missing product list" do
            expect(acc.accepted?(eula_relationship)).to eq([])
          end
        end

        describe "when the product requires a different license" do
          # p1 requires the FOO license
          it "returns the product in the missing product list" do
            expect(acc.accepted?(product_relationship)).to eq([p1])
          end
        end
      end
    end

    describe "when there is not an existing license file" do
      it "returns the product in the missing product list" do
        expect(File).to receive(:exist?).with(File.join(dir1, p1_filename)).and_return(false)
        expect(File).to receive(:exist?).with(File.join(dir2, p1_filename)).and_return(false)
        expect(acc.accepted?(product_relationship)).to eq([p1])
      end
    end

    describe "#persist" do
      it "stores a single license without children" do
        expect(Dir).to receive(:exist?).with(dir3).and_return(true)
        expect(File).to receive(:open).with(File.join(dir3, p1_filename), mode).and_yield(file)
        expect(file).to receive(:<<) do |yaml|
          yaml = YAML.load(yaml)
          expect(yaml["id"]).to eq(p1_id)
          expect(yaml["name"]).to eq(p1_pretty)
          expect(yaml["accepting_product"]).to eq(p1_id)
          expect(yaml["accepting_product_version"]).to eq(version)
        end
        expect(acc.persist(product_relationship, [p1])).to eq([])
      end

      describe "when license has children" do
        let(:p2_id) { "bar" }
        let(:p2_filename) { "p2_filename" }
        let(:p2_pretty) { "Other Pretty Name" }
        let(:p2) { instance_double(LicenseAcceptance::Product, id: p2_id, filename: p2_filename, pretty_name: p2_pretty, license: l1) }
        let(:product_relationship) {
          instance_double(
            LicenseAcceptance::ProductRelationship,
            parent: p1,
            children: [p2],
            parent_version: version
          )
        }

        it "stores a license file for all" do
          expect(Dir).to receive(:exist?).with(dir3).and_return(true)
          expect(File).to receive(:open).with(File.join(dir3, p1_filename), mode).and_yield(file)
          expect(file).to receive(:<<) do |yaml|
            yaml = YAML.load(yaml)
            expect(yaml["id"]).to eq(p1_id)
            expect(yaml["name"]).to eq(p1_pretty)
            expect(yaml["accepting_product"]).to eq(p1_id)
            expect(yaml["accepting_product_version"]).to eq(version)
          end
          expect(File).to receive(:open).with(File.join(dir3, p2_filename), mode).and_yield(file)
          expect(file).to receive(:<<) do |yaml|
            yaml = YAML.load(yaml)
            expect(yaml["id"]).to eq(p2_id)
            expect(yaml["name"]).to eq(p2_pretty)
            expect(yaml["accepting_product"]).to eq(p1_id)
            expect(yaml["accepting_product_version"]).to eq(version)
          end
          expect(acc.persist(product_relationship, [p1, p2])).to eq([])
        end

        describe "when parent is already persisted" do
          it "only stores a license file for the child" do
            expect(Dir).to receive(:exist?).with(dir3).and_return(true)
            expect(File).to receive(:open).once.with(File.join(dir3, p2_filename), mode).and_yield(file)
            expect(file).to receive(:<<) do |yaml|
              yaml = YAML.load(yaml)
              expect(yaml["id"]).to eq(p2_id)
              expect(yaml["name"]).to eq(p2_pretty)
              expect(yaml["accepting_product"]).to eq(p1_id)
              expect(yaml["accepting_product_version"]).to eq(version)
            end
            expect(acc.persist(product_relationship, [p2])).to eq([])
          end
        end
      end

      describe "when the folder cannot be created" do
        let(:err) { StandardError.new("foo") }
        it "returns the error" do
          expect(Dir).to receive(:exist?).with(dir3).and_return(false)
          expect(FileUtils).to receive(:mkdir_p).and_raise(err)
          expect(File).to_not receive(:open)
          expect(acc.persist(product_relationship, [p1])).to eq([err])
        end
      end

      describe "when the file cannot be written" do
        let(:err) { StandardError.new("bar") }
        it "returns the error" do
          expect(Dir).to receive(:exist?).with(dir3).and_return(true)
          expect(File).to receive(:open).with(File.join(dir3, p1_filename), mode).and_raise(err)
          expect(acc.persist(product_relationship, [p1])).to eq([err])
        end
      end
    end

  end
end
