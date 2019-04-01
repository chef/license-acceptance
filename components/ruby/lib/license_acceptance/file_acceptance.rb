require 'date'
require 'yaml'
require 'fileutils'
require 'etc'
require "license_acceptance/logger"

module LicenseAcceptance
  class FileAcceptance
    include Logger

    attr_reader :config

    def initialize(config)
      @config = config
    end

    INVOCATION_TIME = DateTime.now.freeze

    # For all the given products in the product set, search all possible locations for the
    # license acceptance files.
    def check(product_relationship)
      searching = [product_relationship.parent] + product_relationship.children
      missing_licenses = searching.clone
      logger.debug("Searching for the following licenses: #{missing_licenses.map(&:name)}")

      searching.each do |product|
        found = false
        config.license_locations.each do |loc|
          f = File.join(loc, product.filename)
          if File.exist?(f)
            found = true
            logger.debug("Found license #{product.filename} at #{f}")
            missing_licenses.delete(product)
            break
          end
        end
        break if missing_licenses.empty?
      end
      logger.debug("Missing licenses remaining: #{missing_licenses.map(&:name)}")
      missing_licenses
    end

    def persist(product_relationship, missing_licenses)
      parent = product_relationship.parent
      parent_version = product_relationship.parent_version
      root_dir = config.persist_location

      if missing_licenses.include?(parent)
        persist_license(root_dir, parent, parent, parent_version)
      end
      product_relationship.children.each do |child|
        if missing_licenses.include?(child)
          persist_license(root_dir, child, parent, parent_version)
        end
      end
    end

    private

    def persist_license(folder_path, product, parent, parent_version)
      if !Dir.exist?(folder_path)
        FileUtils.mkdir_p(folder_path)
      end
      path = File.join(folder_path, product.filename)

      logger.info("Persisting a license for #{product.name} at path #{path}")
      # TODO do we care if there is an existing file?
      File.open(path, "w") do |license_file|
        contents = {
          name: product.name,
          date_accepted: INVOCATION_TIME.iso8601,
          accepting_product: parent.name,
          accepting_product_version: parent_version,
          user: Etc.getlogin,
          file_format: 1,
        }
        contents = Hash[contents.map { |k, v| [k.to_s, v] }]
        license_file << YAML.dump(contents)
      end
    end

  end
end
