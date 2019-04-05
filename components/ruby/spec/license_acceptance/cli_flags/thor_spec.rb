require "spec_helper"
require "license_acceptance/cli_flags/thor"
require "thor"

class TestThorKlass < Thor
  include LicenseAcceptance::CLIFlags::Thor
end

RSpec.describe LicenseAcceptance::CLIFlags::Thor do
  let(:klass) { TestThorKlass.new }
  it "adds the correct command line flag" do
    expect(klass.class.class_options.keys).to eq([:chef_license])
  end
end
