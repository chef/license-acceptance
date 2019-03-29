require 'logger'
require 'tty-platform'

module LicenseAcceptance
  class Config
    attr_accessor :output, :logger, :license_locations, :persist_location, :persist

    def initialize(opts={})
      @output = opts.fetch(:output, $stdout)
      @logger = opts.fetch(:logger, ::Logger.new(IO::NULL))
      # TODO Windows paths, and different logic based on root/Administrator user
      @license_locations = opts.fetch(:license_locations, default_license_locations)
      @license_locations = [ @license_locations ].flatten
      @persist_location = opts.fetch(:persist_location, default_persist_location)
      @persist = opts.fetch(:persist, true)
    end

    private

    def platform
      @platform ||= TTY::Platform.new
    end

    def is_root?
      Process.uid == 0
    end

    def default_license_locations
      if platform.windows?
        l = [ File.join(ENV["HOMEDRIVE"], "chef/accepted_licenses/") ]
        unless is_root?
          # Look through a list of possible user locations and pick the first one that exists
          # copied from path_helper.rb in chef-config gem
          possible_dirs = []
          possible_dirs << ENV["HOME"] if ENV["HOME"]
          possible_dirs << ENV["HOMEDRIVE"] + ENV["HOMEPATH"] if ENV["HOMEDRIVE"] && ENV["HOMEPATH"]
          possible_dirs << ENV["HOMESHARE"] + ENV["HOMEPATH"] if ENV["HOMESHARE"] && ENV["HOMEPATH"]
          possible_dirs << ENV["USERPROFILE"] if ENV["USERPROFILE"]
          raise NoValidEnvironmentVar if possible_dirs.empty?
          possible_dirs.each do |possible_dir|
            if Dir.exist?(possible_dir)
              full_possible_dir = File.join(possible_dir, ".chef/accepted_licenses/")
              l << full_possible_dir
              break
            end
          end
        end
      else
        l = [ "/etc/chef/accepted_licenses/" ]
        l << File.join(ENV['HOME'], ".chef/accepted_licenses/") unless is_root?
      end
      l
    end

    def default_persist_location
      license_locations[-1]
    end

  end

  class NoValidEnvironmentVar < StandardError
    def initialize
      super("no valid environment variables set on Windows")
    end
  end
end
