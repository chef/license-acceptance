require "forwardable"
require "license_acceptance/config"
require "license_acceptance/logger"
require "license_acceptance/product_reader"
require "license_acceptance/product_relationship"
require "license_acceptance/strategy/environment"
require "license_acceptance/strategy/file"
require "license_acceptance/strategy/argument"
require "license_acceptance/strategy/prompt"
require "license_acceptance/strategy/provided_value"

module LicenseAcceptance
  class Acceptor
    extend Forwardable
    include Logger

    attr_reader :config, :product_reader, :env_strategy, :file_strategy, :arg_strategy, :prompt_strategy, :provided_strategy

    def initialize(opts={})
      @config = Config.new(opts)
      Logger.initialize(config.logger)
      @product_reader = ProductReader.new
      @env_strategy = Strategy::Environment.new(ENV)
      @file_strategy = Strategy::File.new(config)
      @arg_strategy = Strategy::Argument.new(ARGV)
      @prompt_strategy = Strategy::Prompt.new(config)
      @provided_strategy = Strategy::ProvidedValue.new(opts.fetch(:provided, nil))
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
      if accepted_no_persist?
        logger.debug("Chef License accepted with no persistence")
        return true
      end

      product_reader.read
      product_relationship = product_reader.lookup(product_name, version)

      missing_licenses = file_strategy.accepted?(product_relationship)

      # They have already accepted all licenses and stored their acceptance in the persistent files
      if missing_licenses.empty?
        logger.debug("All licenses present")
        return true
      end

      if accepted? || accepted_silent?
        if config.persist
          errs = file_strategy.persist(product_relationship, missing_licenses)
          if errs.empty?
            output_num_persisted(missing_licenses.size) unless accepted_silent?
          else
            output_persist_failed(errs)
          end
        end
        return true
      elsif config.output.isatty && prompt_strategy.request(missing_licenses) do
          if config.persist
            file_strategy.persist(product_relationship, missing_licenses)
          else
            []
          end
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

    def accepted?
      provided_strategy.accepted? || env_strategy.accepted? || arg_strategy.accepted?
    end

    # no-persist is silent too
    def accepted_no_persist?
      provided_strategy.no_persist? || env_strategy.no_persist? || arg_strategy.no_persist?
    end

    # persist but be silent like no-persist
    def accepted_silent?
      provided_strategy.silent? || env_strategy.silent? || arg_strategy.silent?
    end

    # In the case where users accept with a command line argument or environment variable
    # we still want to output the fact that the filesystem was changed.
    def output_num_persisted(count)
      s = count > 1 ? "s": ""
      output.puts <<~EOM
      #{Strategy::Prompt::BORDER}
      #{Strategy::Prompt::CHECK} #{count} product license#{s} accepted.
      #{Strategy::Prompt::BORDER}
      EOM
    end

    def output_persist_failed(errs)
      output.puts <<~EOM
      #{Strategy::Prompt::BORDER}
      #{Strategy::Prompt::CHECK} Product license accepted.
      Could not persist acceptance:\n\t* #{errs.map(&:message).join("\n\t* ")}
      #{Strategy::Prompt::BORDER}
      EOM
    end

  end

  class LicenseNotAcceptedError < RuntimeError
    def initialize(missing_licenses)
      msg = "Missing licenses for the following:\n* " + missing_licenses.join("\n* ")
      super(msg)
    end
  end

end
