require "forwardable"
require "license_acceptance/config"
require "license_acceptance/logger"
require "license_acceptance/product_reader"
require "license_acceptance/product_relationship"
require "license_acceptance/file_acceptance"
require "license_acceptance/arg_acceptance"
require "license_acceptance/prompt_acceptance"

module LicenseAcceptance
  class Acceptor
    extend Forwardable
    include Logger

    attr_reader :config, :product_reader, :file_acceptance, :arg_acceptance, :prompt_acceptance

    def initialize(opts={})
      @config = Config.new(opts)
      Logger.initialize(config.logger)
      @product_reader = ProductReader.new
      @file_acceptance = FileAcceptance.new(config)
      @arg_acceptance = ArgAcceptance.new
      @prompt_acceptance = PromptAcceptance.new(config)
    end

    def_delegator :@config, :output

    # For applications that just need simple logic to handle a failed license acceptance flow we include this small
    # wrapper. Apps with more complex logic (like logging to a logging engine) should call the non-bang version and
    # handle the exception.
    def check_and_persist!(product_name, version)
      check_and_persist(product_name, version)
    rescue LicenseNotAcceptedError
      output.puts "#{product_name} cannot execute without accepting the license"
      exit 172
    end

    def check_and_persist(product_name, version)
      # flag for test environments to set - not for use by consumers
      if ENV['CHEF_LICENSE_NO_PERSIST'] && ENV['CHEF_LICENSE_NO_PERSIST'].downcase == 'accept'
        logger.debug("CHEF_LICENSE_NO_PERSIST accepted")
        return true
      end

      product_reader.read
      product_relationship = product_reader.lookup(product_name, version)

      missing_licenses = file_acceptance.check(product_relationship)

      # They have already accepted all licenses and stored their acceptance in the persistent files
      if missing_licenses.empty?
        logger.debug("All licenses present")
        return true
      end

      # They passed the --accept-license flag on the command line
      if arg_acceptance.check(ARGV) do
          file_acceptance.persist(product_relationship, missing_licenses) if config.persist
        end
        return true
      # TODO what if they have accepted the license for chef, but a new child gets added? Seems like we need to ask for
      # the new children
      # TODO what if they are not running in a TTY?
      elsif prompt_acceptance.request(missing_licenses) do
          file_acceptance.persist(product_relationship, missing_licenses) if config.persist
        end
        return true
      else
        raise LicenseNotAcceptedError.new(missing_licenses)
      end
    end

    def self.check_and_persist!(product_name, version, opts={})
      new(opts).check_and_persist!(product_name, version)
    end

    def self.check_and_persist(product_name, version, opts={})
      new(opts).check_and_persist(product_name, version)
    end

  end

  class LicenseNotAcceptedError < RuntimeError
    def initialize(missing_licenses)
      msg = "Missing licenses for the following:\n* " + missing_licenses.join("\n* ")
      super(msg)
    end
  end

end
