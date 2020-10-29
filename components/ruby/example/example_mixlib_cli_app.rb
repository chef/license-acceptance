#!/usr/bin/env ruby

$LOAD_PATH.unshift File.join(File.expand_path("..", __dir__), "lib/")

require "mixlib/cli"
require "license_acceptance/acceptor"
require "license_acceptance/cli_flags/mixlib_cli"
require "logger"

class ExampleMixlibCLIApp
  include Mixlib::CLI
  include LicenseAcceptance::CLIFlags::MixlibCLI

  option :help,
    short: "-h",
    long: "--help",
    description: "Show this message",
    on: :tail,
    boolean: true,
    show_options: true,
    exit: 0

  def run(argv = ARGV)
    unless ARGV.include?("--help") || ARGV.include?("-h")
      options = {}

      if ENV["LOG_LEVEL"]
        logger = Logger.new(STDOUT)
        logger.level = ENV["LOG_LEVEL"]

        options[:logger] = logger
      end

      if ENV["DEBUG_LICENSE"]
        options[:provided] = ENV["DEBUG_LICENSE"]
      end

      LicenseAcceptance::Acceptor.check_and_persist!("chef-workstation", "1337", options)
    end

    parse_options(argv)
  end
end

cli = ExampleMixlibCLIApp.new
cli.run

puts "BIG SUCCESS"
