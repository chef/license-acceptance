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
  let(:p1_name) { "chef-infra" }
  let(:p1_filename) { "p1_filename" }
  let(:p1) { instance_double(LicenseAcceptance::Product, name: p1_name, filename: p1_filename) }
  let(:version) { "0.1.0" }
  let(:product_relationship) { instance_double(LicenseAcceptance::ProductRelationship, parent: p1, children: [], parent_version: version) }
  let(:mode) { File::WRONLY | File::CREAT | File::EXCL }

  describe "#check" do
    describe "when there is an existing license file" do
      it "returns an empty missing product list" do
        expect(File).to receive(:exist?).with(File.join(dir1, p1_filename)).and_return(true)
        expect(acc.accepted?(product_relationship)).to eq([])
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
      let(:file) { double("file") }

      it "stores a single license without children" do
        expect(Dir).to receive(:exist?).with(dir3).and_return(true)
        expect(File).to receive(:open).with(File.join(dir3, p1_filename), mode).and_yield(file)
        expect(file).to receive(:<<) do |yaml|
          yaml = YAML.load(yaml)
          expect(yaml["name"]).to eq(p1_name)
          expect(yaml["accepting_product"]).to eq(p1_name)
          expect(yaml["accepting_product_version"]).to eq(version)
        end
        expect(acc.persist(product_relationship, [p1])).to eq([])
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
          expect(Dir).to receive(:exist?).with(dir3).and_return(true)
          expect(File).to receive(:open).with(File.join(dir3, p1_filename), mode).and_yield(file)
          expect(file).to receive(:<<) do |yaml|
            yaml = YAML.load(yaml)
            expect(yaml["name"]).to eq(p1_name)
            expect(yaml["accepting_product"]).to eq(p1_name)
            expect(yaml["accepting_product_version"]).to eq(version)
          end
          expect(File).to receive(:open).with(File.join(dir3, p2_filename), mode).and_yield(file)
          expect(file).to receive(:<<) do |yaml|
            yaml = YAML.load(yaml)
            expect(yaml["name"]).to eq(p2_name)
            expect(yaml["accepting_product"]).to eq(p1_name)
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
              expect(yaml["name"]).to eq(p2_name)
              expect(yaml["accepting_product"]).to eq(p1_name)
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
