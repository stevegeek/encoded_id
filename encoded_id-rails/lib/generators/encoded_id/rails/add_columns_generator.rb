# frozen_string_literal: true

require "rails/generators/active_record/migration"

module EncodedId
  module Rails
    module Generators
      # Generator for adding encoded ID columns to models
      # Usage: rails generate encoded_id:rails:add_columns Model [Model2 Model3 ...]
      class AddColumnsGenerator < ::Rails::Generators::Base
        include ::ActiveRecord::Generators::Migration
        
        source_root File.expand_path(__dir__)
        
        argument :model_names, type: :array, desc: "Model name or names to add columns to"
        
        desc "Adds encoded_id persistence columns to the specified models"
        
        def create_migration_file
          migration_template(
            "templates/add_encoded_id_columns_migration.rb.erb",
            "db/migrate/add_encoded_id_columns_to_#{table_names}.rb",
            migration_version: migration_version
          )
        end
        
        private
        
        def table_names
          @table_names ||= model_names.map do |model_name|
            model_name.underscore.pluralize
          end.join("_and_")
        end
        
        def migration_version
          "[#{::ActiveRecord::VERSION::MAJOR}.#{::ActiveRecord::VERSION::MINOR}]"
        end
        
        def migration_class_name
          "AddEncodedIdColumnsTo#{table_names.camelize}"
        end
      end
    end
  end
end