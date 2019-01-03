require "spec_helper"
require "license_acceptance/acceptor"

RSpec.describe LicenseAcceptance::Acceptor do
  it "has a version number" do
    expect(LicenseAcceptance::VERSION).not_to be nil
  end
end
