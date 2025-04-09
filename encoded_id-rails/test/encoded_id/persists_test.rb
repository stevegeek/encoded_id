# frozen_string_literal: true

require "test_helper"

class EncodedId::PersistsTest < Minitest::Test
  def setup
    # Store the original configuration
    @original_config = EncodedId::Rails.configuration
  end

  def teardown
    # Restore the original configuration
    EncodedId::Rails.instance_variable_set(:@configuration, @original_config)
  end

  def test_it_sets_normalized_encoded_id_on_create
    model = ModelWithPersistedEncodedId.create!(foo: "bar")
    assert_equal ModelWithPersistedEncodedId.encode_normalized_encoded_id(model.id), model.normalized_encoded_id
  end

  def test_it_sets_normalized_encoded_id_on_update
    model = ModelWithPersistedEncodedId.create!(foo: "bar")
    assert_equal ModelWithPersistedEncodedId.encode_normalized_encoded_id(model.id), model.normalized_encoded_id
    model.update!(id: model.id + 1000)
    assert_equal ModelWithPersistedEncodedId.encode_normalized_encoded_id(model.id), model.normalized_encoded_id
  end

  def test_it_sets_prefixed_encoded_id_on_create
    model = ModelWithPersistedEncodedId.create!(foo: "bar")
    assert_equal model.encoded_id, model.prefixed_encoded_id
  end

  def test_it_sets_prefixed_encoded_id_on_update
    model = ModelWithPersistedEncodedId.create!(foo: "bar")
    assert_equal model.encoded_id, model.prefixed_encoded_id
    model.update!(id: model.id + 1000)
    assert_equal model.encoded_id, model.prefixed_encoded_id
  end

  def test_dup_resets_persisted_encoded_id_columns
    model = ModelWithPersistedEncodedId.create!(foo: "bar")
    duped_model = model.dup

    assert_nil duped_model.normalized_encoded_id
    assert_nil duped_model.prefixed_encoded_id
    refute duped_model.normalized_encoded_id_changed?
    refute duped_model.prefixed_encoded_id_changed?
  end

  def test_cannot_directly_update_normalized_encoded_id
    model = ModelWithPersistedEncodedId.create!(foo: "bar")
    model.normalized_encoded_id = "something-else"

    assert_raises(ActiveRecord::ReadonlyAttributeError) do
      model.save!
    end
  end

  def test_cannot_directly_update_prefixed_encoded_id
    model = ModelWithPersistedEncodedId.create!(foo: "bar")
    model.prefixed_encoded_id = "something-else"

    assert_raises(ActiveRecord::ReadonlyAttributeError) do
      model.save!
    end
  end

  def test_raises_if_setting_encoded_id_on_unpersisted_record
    model = ModelWithPersistedEncodedId.new(foo: "bar")

    assert_raises(StandardError, /not persisted/) do
      model.set_normalized_encoded_id!
    end
  end

  def test_raises_if_persisted_encoded_id_does_not_match_computed_encoded_id
    model = ModelWithPersistedEncodedId.create!(foo: "bar")

    model.update_column(:normalized_encoded_id, "foo")

    assert_raises(StandardError, /not the same as currently computing/) do
      model.check_encoded_id_persisted!
    end
  end

  def test_raises_if_persisted_prefixed_encoded_id_does_not_match_computed_encoded_id
    model = ModelWithPersistedEncodedId.create!(foo: "bar")

    model.update_column(:prefixed_encoded_id, "foo")

    assert_raises(StandardError, /not correct/) do
      model.check_encoded_id_persisted!
    end
  end
end
