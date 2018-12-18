require 'tty-prompt'

module LicenseAcceptance
  class PromptAcceptance

    def self.request(product_set, missing_licenses)
      msg = <<~EOD
        You are about the accept the license for:
        * #{product_set.parent}
        By accepting this license you also accept the license for
        * #{missing_licenses.join("\n* ")}
      EOD
      prompt = TTY::Prompt.new
      prompt.yes?(msg) do |q|
        q.suffix 'yes/no'
      end
    end

  end
end
