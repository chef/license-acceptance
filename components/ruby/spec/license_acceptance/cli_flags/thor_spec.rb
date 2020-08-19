require "spec_helper"
require "license_acceptance/cli_flags/thor"
require "thor"

RSpec.describe LicenseAcceptance::CLIFlags::Thor do
  let(:klass) do
    Class.new(Thor) do
      include LicenseAcceptance::CLIFlags::Thor
    end
  end

  # Thor writes the usage information to STDOUT in each of the following tests.
  around do |example|
    original_stdout = STDOUT.dup
    STDOUT.reopen(File::NULL)
    example.call
  ensure
    STDOUT.reopen(original_stdout)
    original_stdout.close
  end

  it "adds the correct command line flag" do
    expect(klass.class_options.keys).to eq([:chef_license])
  end

  %w(accept accept-no-persist accept-silent).each do |license_value|
    it "does not warn when setting the flag to '#{license_value}'" do
      msg = /Expected '--chef-license' to be one of accept, accept-no-persist, accept-silent/

      expect {
        klass.start(["--chef_license=#{license_value}"])
      }.not_to output(msg).to_stderr
    end
  end

  it "warns when setting the flag to unrecognized values" do
    msg = /Expected '--chef-license' to be one of accept, accept-no-persist, accept-silent; got foo/

    expect {
      klass.start(["--chef_license=foo"])
    }.to output(msg).to_stderr
  end
end
