require "spec_helper"
require "license_acceptance/cli_flags/mixlib_cli"

RSpec.describe LicenseAcceptance::CLIFlags::MixlibCLI do
  let(:klass) do
    Class.new do
      include Mixlib::CLI
      include LicenseAcceptance::CLIFlags::MixlibCLI
    end.new
  end

  it "adds the correct command line flag" do
    expect(klass.options).to include(:chef_license)
  end

  %w{accept accept-no-persist accept-silent}.each do |license_value|
    it "allows setting the flag to '#{license_value}'" do
      klass.parse_options(["--chef-license", license_value])
      expect(klass.config[:chef_license]).to eq(license_value)
    end
  end

  it "does not allow setting the flag to unrecognized values" do
    msg = /--chef-license: foo is not one of the allowed values: 'accept', 'accept-no-persist', or 'accept-silent'/

    expect {
      klass.parse_options(["--chef-license", "foo"])
    }.to raise_error(SystemExit).and output(msg).to_stdout
  end
end
