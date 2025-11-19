# frozen_string_literal: true

require "rails/generators/base"

module EncodedId
  module Rails
    module Generators
      # The Install generator `encoded_id:rails:install`
      class InstallGenerator < ::Rails::Generators::Base
        source_root File.expand_path(__dir__)

        desc "Creates an encoder-specific initializer for the gem."

        class_option :encoder,
                     type: :string,
                     aliases: "-e",
                     desc: "Encoder to use (sqids or hashids)",
                     default: nil

        def ask_for_encoder
          @encoder = options[:encoder]

          unless @encoder
            @encoder = ask("Which encoder would you like to use?",
                          limited_to: %w[sqids hashids],
                          default: "sqids")
          end

          unless %w[sqids hashids].include?(@encoder)
            say "Invalid encoder '#{@encoder}'. Must be 'sqids' or 'hashids'.", :red
            exit 1
          end
        end

        def copy_tasks
          template_name = @encoder == "sqids" ? "sqids_encoded_id.rb" : "hashids_encoded_id.rb"
          template "templates/#{template_name}", "config/initializers/encoded_id.rb"
        end

        def show_readme
          say "\n" + ("=" * 70), :green
          if @encoder == "sqids"
            say "Sqids encoder installed!", :green
            say "This encoder does not require a salt and generates URL-safe IDs.", :green
          else
            say "Hashids encoder installed!", :green
            say "⚠️  IMPORTANT: You MUST configure a salt in config/initializers/encoded_id.rb", :yellow
            say "Uncomment and set the 'config.salt' line before using Hashids.", :yellow
          end
          say ("=" * 70) + "\n", :green
        end
      end
    end
  end
end
