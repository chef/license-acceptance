require 'logger'

module LicenseAcceptance
  class Config
    attr_accessor :output, :logger, :license_locations, :persist_location

    def initialize(opts={})
      @output = opts.fetch(:output, $stdout)
      @logger = opts.fetch(:logger, ::Logger.new(IO::NULL))
      # TODO Windows paths, and different logic based on root/Administrator user
      @license_locations = opts.fetch(:license_locations) do
        [
          File.join(ENV['HOME'], '.chef', 'accepted_licenses'),
          "/etc/chef/accepted_licenses",
        ]
      end
      @persist_location = license_locations[0]
    end

  end
end
