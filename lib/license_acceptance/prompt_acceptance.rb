require 'tty-prompt'
require 'pastel'

module LicenseAcceptance
  class PromptAcceptance

    def self.request(product_set, missing_licenses)
      pastel = Pastel.new
      msg = <<~EOD
        You are about the accept the license for:
        * #{pastel.green(product_set.parent)}
        By accepting this license you also accept the license for
        * #{missing_licenses.join("\n* ")}
      EOD
      puts msg
      prompt = TTY::Prompt.new
      prompt.yes?("Do you accept the license(s)?") do |q|
        q.suffix 'yes/no'
      end
    end

  end
end
