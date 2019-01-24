require 'tty-prompt'
require 'pastel'

module LicenseAcceptance
  class PromptAcceptance
    WIDTH = 50.freeze
    PASTEL = Pastel.new
    BORDER = "+---------------------------------------------+".freeze

    def self.request(missing_licenses, output, &accepted_callback)
      c = missing_licenses.size
      s = c > 1 ? "s": ""
      yes = PASTEL.green.bold("yes")
      check = PASTEL.green("✔")
      acceptance_question = "Do you accept the #{c} product license#{s} (#{yes}/no)?"
      output.puts <<~EOM
      #{BORDER}
                  Chef License Acceptance

      Before you can continue, #{c} product license#{s}
      must be accepted. View the license at
      https://docs.chef.io/chef_license.html

      License#{s} that need accepting:
        * #{missing_licenses.map(&:pretty_name).join("\n  * ")}

      #{acceptance_question}

      EOM

      if ask(output, c, s, check, accepted_callback)
        return true
      end

      output.puts <<~EOM

      If you do not accept this license you will
      not be able to use Chef products.

      #{acceptance_question}

      EOM

      answer = ask(output, c, s, check, accepted_callback)
      if answer != "yes"
        output.puts BORDER
      end
      return answer
    end

    private

    def self.ask(output, c, s, check, accepted_callback)
      # TODO https://github.com/piotrmurach/tty-prompt#34-interrupt
      prompt = TTY::Prompt.new(track_history: false, active_color: :bold)

      answer = prompt.ask("$") do |q|
        q.modify :down, :trim
        q.required true
        q.messages[:required?] = "You must enter 'yes' or 'no'"
        q.validate /^\s*(yes|no)\s*$/i
        q.messages[:valid?] = "You must enter 'yes' or 'no'"
      end

      if answer == "yes"
        output.puts
        output.puts "Accepting #{c} product license#{s}..."
        accepted_callback.call
        output.puts <<~EOM
        #{check} #{c} product license#{s} accepted.
        #{BORDER}

        EOM
        return true
      end
      return false
    end

  end
end
