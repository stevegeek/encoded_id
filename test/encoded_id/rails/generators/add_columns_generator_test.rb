# frozen_string_literal: true

require "test_helper"
require "rails/generators/test_case"
require "generators/encoded_id/rails/add_columns_generator"

module EncodedId
  module Rails
    module Generators
      class AddColumnsGeneratorTest < ::Rails::Generators::TestCase
        tests AddColumnsGenerator
        destination File.expand_path("../../../tmp", __dir__)
        setup :prepare_destination

        test "generator creates migration with single model" do
          run_generator ["User"]
          assert_migration "db/migrate/add_encoded_id_columns_to_users.rb" do |migration|
            assert_match(/table_name = :users/, migration)
            assert_match(/add_column table_name, :normalized_encoded_id, :string/, migration)
            assert_match(/add_column table_name, :prefixed_encoded_id, :string/, migration)
            assert_match(/add_index table_name, :normalized_encoded_id, unique: true/, migration)
            assert_match(/add_index table_name, :prefixed_encoded_id, unique: true/, migration)
          end
        end

        test "generator creates migration with multiple models" do
          run_generator ["User", "Product"]
          assert_migration "db/migrate/add_encoded_id_columns_to_users_and_products.rb" do |migration|
            # Test for User model columns
            assert_match(/table_name = :users/, migration)
            assert_match(/add_column table_name, :normalized_encoded_id, :string/, migration)
            assert_match(/add_column table_name, :prefixed_encoded_id, :string/, migration)
            assert_match(/add_index table_name, :normalized_encoded_id, unique: true/, migration)
            assert_match(/add_index table_name, :prefixed_encoded_id, unique: true/, migration)

            # Test for Product model columns
            assert_match(/table_name = :products/, migration)
          end
        end
      end
    end
  end
end
