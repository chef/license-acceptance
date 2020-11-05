require "date"
autoload :YAML, "yaml"
require "fileutils" unless defined?(FileUtils)
require "etc" unless defined?(Etc)
require_relative "../logger"
require_relative "base"

module LicenseAcceptance
  module Strategy

    # Read and write marker files that show acceptance.
    class File < Base
      include Logger

      attr_reader :config

      def initialize(config)
        @config = config
      end

      INVOCATION_TIME = DateTime.now.freeze

      # For all the given products in the product set, search all possible locations for the
      # license acceptance files.
      def accepted?(product_relationship)
        searching = [product_relationship.parent] + product_relationship.children
        missing_licenses = searching.clone
        logger.debug("Searching for the following licenses: #{missing_licenses.map(&:id)}")

        searching.each do |product|
          config.license_locations.each do |loc|
            license_path = ::File.join(loc, product.filename)
            next unless ::File.exist?(license_path)

            license = YAML.load_file(license_path)

            # If the license file is missing the license_name field,
            # assume it represents the EULA
            license["license_name"] ||= "EULA"

            if product.license.name == license["license_name"]
              # It is possible to have previously accepted a product under the EULA license but that
              # product is actually covered under MLSA, so we need to check it.
              logger.debug("Found license #{product.filename} at #{license_path}")
              missing_licenses.delete(product)
            end
          end
          break if missing_licenses.empty?
        end
        logger.debug("Missing licenses remaining: #{missing_licenses.map(&:id)}")
        missing_licenses
      end

      def persist(product_relationship, missing_licenses)
        parent = product_relationship.parent
        parent_version = product_relationship.parent_version
        root_dir = config.persist_location

        unless Dir.exist?(root_dir)
          begin
            FileUtils.mkdir_p(root_dir)
          rescue StandardError => e
            msg = "Could not create license directory #{root_dir}"
            logger.info "#{msg}\n\t#{e.message}\n\t#{e.backtrace.join("\n\t")}"
            return [e]
          end
        end

        errs = []
        if missing_licenses.include?(parent)
          err = persist_license(root_dir, parent, parent, parent_version)
          errs << err unless err.nil?
        end
        product_relationship.children.each do |child|
          if missing_licenses.include?(child)
            err = persist_license(root_dir, child, parent, parent_version)
            errs << err unless err.nil?
          end
        end
        errs
      end

      private

      def persist_license(folder_path, product, parent, parent_version)
        path = ::File.join(folder_path, product.filename)
        logger.info("Persisting a license for #{product.pretty_name} at path #{path}")
        ::File.open(path, ::File::WRONLY | ::File::CREAT | ::File::TRUNC) do |license_file|
          contents = {
            id: product.id,
            name: product.pretty_name,
            date_accepted: INVOCATION_TIME.iso8601,
            accepting_product: parent.id,
            accepting_product_version: parent_version,
            user: Etc.getlogin,
            file_format: 1,
            license_name: product.license.name,
          }
          contents = Hash[contents.map { |k, v| [k.to_s, v] }]
          license_file << YAML.dump(contents)
        end
        nil
      rescue StandardError => e
        msg = "Could not persist license to #{path}"
        logger.info "#{msg}\n\t#{e.message}\n\t#{e.backtrace.join("\n\t")}"
        e
      end

    end
  end
end
