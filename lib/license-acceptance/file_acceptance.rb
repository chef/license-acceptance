require 'date'
require 'yaml'
require 'fileutils'
require 'etc'

module LicenseAcceptance
  class FileAcceptance

    # TODO pull these from Chef (the workstation config loader maybe?)
    POSSIBLE_LOCATIONS = [
      File.join(ENV['HOME'], '.chef', 'accepted_licenses'),
      "/etc/chef/accepted_licenses",
    ].freeze
    INVOCATION_TIME = DateTime.now.freeze

    # For all the given products in the product set, search all possible locations for the
    # license acceptance files.
    def self.check(product_set)
      searching = [product_set.parent] + product_set.children
      missing_licenses = searching.clone

      searching.each do |license|
        found = false
        POSSIBLE_LOCATIONS.each do |loc|
          f = File.join(loc, license)
          if File.exist?(f)
            found = true
            missing_licenses.delete(license)
            break
          end
        end
        break if missing_licenses.empty?
      end
      missing_licenses
    end

    # TODO how do we know when to set it in /etc and when in ENV['HOME'] ?
    def self.persist(product_set, missing_licenses)
      parent = product_set.parent
      parent_version = product_set.parent_version
      to_persist = [parent] + product_set.children
      if missing_licenses.include?(parent)
        persist_license(POSSIBLE_LOCATIONS[0], parent, parent, parent_version)
      end
      product_set.children.each do |child|
        if missing_licenses.include?(child)
          persist_license(POSSIBLE_LOCATIONS[0], child, parent, parent_version)
        end
      end
    end

    private

    def self.persist_license(folder_path, name, parent, parent_version)
      if !Dir.exist?(folder_path)
        FileUtils.mkdir_p(folder_path)
      end
      path = File.join(folder_path, name)

      # TODO do we care if there is an existing file?
      File.open(path, "w") do |license_file|
        contents = {
          name: name,
          date_accepted: INVOCATION_TIME.iso8601,
          accepting_product: parent,
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
