require "spec_helper"
require "license_acceptance/cli_flags/mixlib_cli"

class TestKlass
  include Mixlib::CLI
  include LicenseAcceptance::CLIFlags::MixlibCLI
end

RSpec.describe LicenseAcceptance::CLIFlags::MixlibCLI do
  let(:klass) { TestKlass.new }
  it "adds the correct command line flag" do
    expect(klass.options).to include(:accept_license)
  end
end
