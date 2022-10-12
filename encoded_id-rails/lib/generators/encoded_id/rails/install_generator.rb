# frozen_string_literal: true

require "rails/generators/base"

module EncodedId
  module Rails
    module Generators
      # The Install generator `encoded_id-rails:install`
      class InstallGenerator < ::Rails::Generators::Base
        source_root File.expand_path(__dir__)

        desc "Creates an initializer for the gem."
        def copy_tasks
          template "templates/encoded_id.rb", "config/initializers/encoded_id.rb"
        end
      end
    end
  end
end
