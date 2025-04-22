# frozen_string_literal: true

require "test_helper"

class EncodedId::ModelTest < Minitest::Test
  attr_reader :model

  def setup
    # Store the original configuration
    @original_config = EncodedId::Rails.configuration
    @model = MyModel.create(name: "bob")
  end

  def teardown
    # Restore the original configuration
    EncodedId::Rails.instance_variable_set(:@configuration, @original_config)
  end

  def test_encoded_id_hash_returns_nil_for_unsaved_records
    unsaved_model = MyModel.new
    assert_nil unsaved_model.encoded_id_hash
  end

  def test_annotation_for_encoded_id_raises_for_anonymous_class
    # Create an anonymous class that includes EncodedId::Model
    anonymous_class = Class.new(ActiveRecord::Base) do
      include EncodedId::Model
      self.table_name = "my_models"
    end

    # Create an instance of the anonymous class
    record = anonymous_class.new

    # The annotation_for_encoded_id method should raise an error because the class has no name
    error = assert_raises(StandardError) do
      record.annotation_for_encoded_id
    end

    assert_match(/requires the model class to have a name/, error.message)
  end

  def test_encoded_id_hash_is_memoized
    # Call encoded_id_hash to memoize it
    encoded_id_hash = model.encoded_id_hash

    # Verify it's memoized
    assert_equal encoded_id_hash, model.instance_variable_get(:@encoded_id_hash)
  end

  def test_dup_removes_memoized_encoded_id_hash
    # First, ensure encoded_id_hash is memoized
    model.encoded_id_hash
    assert model.instance_variable_defined?(:@encoded_id_hash)

    # Duplicate the model
    duped_model = model.dup

    # Verify the duped model does not have the memoized encoded_id_hash
    refute duped_model.instance_variable_defined?(:@encoded_id_hash)
  end

  def test_dup_removes_memoized_encoded_id
    # First, ensure the encoded_id is memoized on the original model
    original_encoded_id = model.encoded_id
    assert_equal original_encoded_id, model.instance_variable_get(:@encoded_id)

    # Duplicate the model
    duped_model = model.dup

    # Verify the duped model does not have a memoized encoded_id
    refute duped_model.instance_variable_defined?(:@encoded_id)
  end

  def test_dup_removes_memoized_slugged_encoded_id
    # First, ensure the slugged_encoded_id is memoized on the original model
    original_slugged_encoded_id = model.slugged_encoded_id
    assert_equal original_slugged_encoded_id, model.instance_variable_get(:@slugged_encoded_id)

    # Duplicate the model
    duped_model = model.dup

    # Verify the duped model does not have a memoized slugged_encoded_id
    refute duped_model.instance_variable_defined?(:@slugged_encoded_id)
  end

  def test_slugged_id_raises_with_no_method_to_get_slug
    model = ModelWithPersistedEncodedId.create!
    assert_raises StandardError do
      model.slugged_encoded_id
    end
  end

  def test_encoded_id_is_recalculated_when_id_changes_in_memory
    # Get the original encoded_id
    original_encoded_id = model.encoded_id

    # Change the id in memory (without saving)
    model.id = model.id + 1000

    # Get the new encoded_id
    new_encoded_id = model.encoded_id

    # Verify the encoded_id has changed
    refute_equal original_encoded_id, new_encoded_id
  end

  def test_encoded_id_hash_is_recalculated_when_id_changes_in_memory
    # Get the original encoded_id_hash
    original_encoded_id_hash = model.encoded_id_hash

    # Change the id in memory (without saving)
    model.id = model.id + 1000

    # Get the new encoded_id_hash
    new_encoded_id_hash = model.encoded_id_hash

    # Verify the encoded_id_hash has changed
    refute_equal original_encoded_id_hash, new_encoded_id_hash
  end

  def test_memoization_stores_current_id
    # Call encoded_id_hash to memoize it
    model.encoded_id_hash

    # Verify the id used for memoization is stored
    assert_equal model.id, model.encoded_id_memoized_with_id
  end

  def test_clear_encoded_id_cache_removes_all_memoization
    # Memoize all encoded id values
    model.encoded_id_hash
    model.encoded_id
    EncodedId::Rails.configuration.slug_value_method_name = :custom_slug_method
    model.slugged_encoded_id

    # Clear the cache
    model.clear_encoded_id_cache!

    # Verify all memoized values are gone
    refute model.instance_variable_defined?(:@encoded_id_hash)
    refute model.instance_variable_defined?(:@encoded_id)
    refute model.instance_variable_defined?(:@slugged_encoded_id)
    assert_nil model.encoded_id_memoized_with_id

    EncodedId::Rails.configuration.slug_value_method_name = :name_for_encoded_id_slug
  end

  def test_reload_clears_encoded_id_cache
    # Memoize encoded id values
    model.encoded_id_hash
    model.encoded_id

    # Reload the model
    model.reload

    # Verify memoized values are cleared
    refute model.instance_variable_defined?(:@encoded_id_hash)
    refute model.instance_variable_defined?(:@encoded_id)
    assert_nil model.encoded_id_memoized_with_id
  end

  def test_memoization_is_reset_when_id_changes_via_update_column
    # First, get the original encoded_id and memoize it
    original_encoded_id = model.encoded_id
    assert model.instance_variable_defined?(:@encoded_id)

    # Capture the original ID
    original_id = model.id

    # Directly update the ID in the database using update_column
    new_id = original_id + 2000
    model.update_column(:id, new_id)

    # Verify that the ID has changed in the model
    assert_equal new_id, model.id

    # The memoization should be cleared when id != encoded_id_memoized_with_id
    # Get the new encoded_id which should trigger cache invalidation
    new_encoded_id = model.encoded_id

    # Verify the encoded_id has changed
    refute_equal original_encoded_id, new_encoded_id

    # Verify the encoded_id has been re-memoized with the new ID
    assert_equal new_id, model.encoded_id_memoized_with_id
  end

  def test_encoded_id_is_nil_if_model_is_new_record
    assert_nil MyModel.new.encoded_id
  end

  def test_it_gets_encoded_id_for_model
    eid = ::EncodedId::ReversibleId.new(salt: MyModel.encoded_id_salt).encode(model.id)
    assert_equal eid, model.encoded_id_hash
  end

  def test_it_encodes_with_default_annotation
    eid = MyModel.encode_encoded_id(model.id)
    assert_equal "my_model_#{eid}", model.encoded_id
  end

  def test_encoded_id_is_recalculated_if_id_changes
    initial_encoded_id = model.encoded_id
    model.id = model.id + 1
    new_encoded_id = model.encoded_id
    refute_equal initial_encoded_id, new_encoded_id
    assert_equal new_encoded_id, model.instance_variable_get(:@encoded_id)
  end

  def test_it_does_not_slug_encoded_id_for_model_with_no_slug
    # Store original value
    original_method = EncodedId::Rails.configuration.slug_value_method_name

    begin
      # Set to a method that doesn't exist
      EncodedId::Rails.configuration.slug_value_method_name = :oop_wrong_method_name

      assert_raises(StandardError) do
        model.slugged_encoded_id
      end
    ensure
      # Restore original value
      EncodedId::Rails.configuration.slug_value_method_name = original_method
    end
  end

  def test_slugged_encoded_id_is_recalculated_if_id_changes
    initial_encoded_id = model.slugged_encoded_id
    model.id = model.id + 1
    new_encoded_id = model.slugged_encoded_id
    refute_equal initial_encoded_id, new_encoded_id
    assert_equal new_encoded_id, model.instance_variable_get(:@slugged_encoded_id)
  end

  def test_it_gets_slugged_encoded_id_for_model_with_custom_slug_and_annotation
    EncodedId::Rails.configuration.slug_value_method_name = :custom_slug_method
    assert_equal "sluggy--my_model_#{model.encoded_id_hash}", model.slugged_encoded_id
    EncodedId::Rails.configuration.slug_value_method_name = :name_for_encoded_id_slug
  end

  def test_it_gets_default_annotation_for_model
    assert_equal "my_model", model.annotation_for_encoded_id
  end

  def test_duplicated_record_has_different_encoded_id
    refute_equal model.encoded_id, model.dup.encoded_id
  end

  def test_duplicated_record_has_different_slugged_encoded_id
    refute_equal model.slugged_encoded_id, model.dup.slugged_encoded_id
  end

  def test_both_encoded_id_and_slugged_id_are_recalculated_on_duplication
    initial_encoded_id = model.encoded_id
    initial_slugged_encoded_id = model.slugged_encoded_id
    new_model = model.dup
    refute_equal initial_encoded_id, new_model.encoded_id
    refute_equal initial_slugged_encoded_id, new_model.slugged_encoded_id
  end

  def test_both_encoded_id_and_slugged_id_are_recalculated_on_duplication_and_persisted
    initial_encoded_id = model.encoded_id
    initial_slugged_encoded_id = model.slugged_encoded_id
    new_model = model.dup
    new_model.save
    refute_equal initial_encoded_id, new_model.encoded_id
    refute_equal initial_slugged_encoded_id, new_model.slugged_encoded_id
    refute_nil new_model.encoded_id
    refute_nil new_model.slugged_encoded_id
  end
end
