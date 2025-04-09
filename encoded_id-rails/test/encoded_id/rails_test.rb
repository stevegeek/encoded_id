# frozen_string_literal: true

require "test_helper"

class EncodedId::RailsTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::EncodedId::Rails::VERSION
  end

  attr_reader :model

  def setup
    @model = MyModel.create
    EncodedId::Rails.configuration.slug_value_method_name = :custom_slug_method
  end

  def test_configuration_prevents_invalid_group_separator
    assert_raises ArgumentError do
      EncodedId::Rails.configuration.group_separator = "a"
    end
  end

  def test_configuration_prevents_invalid_slugged_id_separator
    assert_raises ArgumentError do
      EncodedId::Rails.configuration.slugged_id_separator = "a"
    end
    EncodedId::Rails.configuration.group_separator = "-"
    assert_raises ArgumentError do
      EncodedId::Rails.configuration.slugged_id_separator = "-"
    end
  end

  def test_configuration_prevents_invalid_annotated_id_separator
    assert_raises ArgumentError do
      EncodedId::Rails.configuration.annotated_id_separator = "a"
    end
  end

  def test_find_by_encoded_id_gets_model_given_encoded_id
    assert_equal model, MyModel.find_by_encoded_id(model.encoded_id)
  end

  def test_find_by_encoded_id_gets_model_given_encoded_id_with_slug
    assert_equal model, MyModel.find_by_encoded_id("my-cool-slug--#{model.encoded_id}")
  end

  def test_find_by_encoded_id_gets_model_given_encoded_id_with_id_constraint
    assert_equal model, MyModel.find_by_encoded_id(model.encoded_id, with_id: model.id)
  end

  def test_find_by_encoded_id_returns_nil_if_no_model_found_for_encoded_id
    assert_nil MyModel.find_by_encoded_id("aaaa-aaaa")
  end

  def test_find_by_encoded_id_returns_nil_if_encoded_id_unhashable
    assert_nil MyModel.find_by_encoded_id("aa%%aaaa")
  end

  def test_find_by_encoded_id_returns_nil_if_constraint_not_met
    assert_nil MyModel.find_by_encoded_id(model.encoded_id, with_id: 12345)
  end

  def test_find_by_encoded_id_bang_gets_model_given_encoded_id
    assert_equal model, MyModel.find_by_encoded_id!(model.encoded_id)
  end

  def test_find_by_encoded_id_bang_gets_model_given_encoded_id_with_id_constraint
    assert_equal model, MyModel.find_by_encoded_id!(model.encoded_id, with_id: model.id)
  end

  def test_find_all_by_encoded_id_gets_models_given_encoded_id
    assert_equal [model], MyModel.find_all_by_encoded_id(model.encoded_id)
  end

  def test_find_all_by_encoded_id_gets_models_given_encoded_ids
    model2 = MyModel.create
    assert_equal [model, model2], MyModel.find_all_by_encoded_id(MyModel.encode_encoded_id([model.id, model2.id]))
  end

  def test_find_all_by_encoded_id_bang_gets_model_given_encoded_id
    assert_equal [model], MyModel.find_all_by_encoded_id!(model.encoded_id)
  end

  def test_find_all_by_encoded_id_bang_raises_if_no_model_found
    assert_raises(ActiveRecord::RecordNotFound) { MyModel.find_all_by_encoded_id!("aaaa-aaaa") }
  end

  def test_find_all_by_encoded_id_bang_raises_if_not_all_models_found
    model2 = MyModel.create
    multi_id = MyModel.encode_encoded_id([model.encoded_id, model2.encoded_id, "aaaa-aaaa"])
    assert_raises(ActiveRecord::RecordNotFound) { MyModel.find_all_by_encoded_id!(multi_id) }
  end

  def test_find_by_encoded_id_bang_raises_if_no_model_found_for_encoded_id
    assert_raises ActiveRecord::RecordNotFound do
      MyModel.find_by_encoded_id!("aaaa-aaaa")
    end
  end

  def test_find_by_encoded_id_bang_raises_if_encoded_id_unhashable
    assert_raises ActiveRecord::RecordNotFound do
      MyModel.find_by_encoded_id!("aa%%%aaa")
    end
  end

  def test_find_by_encoded_id_bang_raises_if_constraint_not_met
    assert_raises ActiveRecord::RecordNotFound do
      MyModel.find_by_encoded_id!(model.encoded_id, with_id: 12345)
    end
  end

  def test_where_encoded_id_returns_relation
    assert_kind_of ActiveRecord::Relation, MyModel.where_encoded_id(model.encoded_id)
  end

  def test_where_encoded_id_gets_model_given_encoded_id
    assert_equal [model], MyModel.where_encoded_id(model.encoded_id).to_a
  end

  def test_where_encoded_id_gets_models_given_encoded_ids
    model2 = MyModel.create
    assert_equal [model, model2], MyModel.where_encoded_id(MyModel.encode_encoded_id([model.id, model2.id])).to_a
  end

  def test_where_encoded_id_gets_model_given_encoded_id_with_slug
    assert_equal [model], MyModel.where_encoded_id("my-cool-slug--#{model.encoded_id}").to_a
  end

  def test_where_encoded_id_returns_empty_relation_if_no_model_found_for_encoded_id
    assert_equal [], MyModel.where_encoded_id("aaaa-aaaa").to_a
  end

  def test_it_encodes_id
    eid = MyModel.encode_encoded_id(model.id)
    assert_kind_of String, eid
    assert_match(/[a-z0-9]{4}-[a-z0-9]{4}/, eid)
    assert_equal model.encoded_id_hash, eid
  end

  def test_it_parses_annotated_ids
    eid = MyModel.encode_encoded_id(model.id)
    assert_kind_of String, eid
    assert_match(/[a-z0-9]{4}-[a-z0-9]{4}/, eid)
    assert_equal EncodedId::Rails::AnnotatedIdParser.new(model.encoded_id).id, eid
  end

  def test_it_encodes_with_default_annotation
    eid = MyModel.encode_encoded_id(model.id)
    assert_equal "my_model_#{eid}", model.encoded_id
  end

  def test_it_gets_encoded_id_with_options
    assert_match(/(..\/){3}../, MyModel.encode_encoded_id(model.id, {
      character_group_size: 2,
      separator: "/"
    }))
  end

  def test_it_gets_encoded_id_with_options_with_nil_group_size
    assert_match(/[^_]+/, MyModel.encode_encoded_id(model.id, {
      character_group_size: nil,
      separator: "_"
    }))
  end

  def test_it_gets_encoded_id_with_options_with_nil_group_size
    assert_match(/.{8}/, MyModel.encode_encoded_id(model.id, {
      character_group_size: 3,
      separator: nil
    }))
  end

  def test_it_decodes_id
    assert_equal [model.id], MyModel.decode_encoded_id(model.encoded_id)
  end

  def test_it_gets_encoded_id_salt
    assert_match("MyModel/the-test-salt", MyModel.encoded_id_salt)
  end

  def test_it_parses_annotation_from_encoded_id
    EncodedId::Rails::AnnotatedIdParser.new(model.encoded_id).tap do |parser|
      assert_equal "my_model", parser.annotation
      assert_equal model.encoded_id_hash, parser.id
    end
  end

  # Persist mixin

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

  # Instance methods

  def test_encoded_id_is_nil_if_model_is_new_record
    assert_nil MyModel.new.encoded_id
  end

  def test_it_gets_encoded_id_for_model
    eid = ::EncodedId::ReversibleId.new(salt: MyModel.encoded_id_salt).encode(model.id)
    assert_equal eid, model.encoded_id_hash
  end

  def test_encoded_id_is_memoized
    encoded_id = model.encoded_id
    assert_equal encoded_id, model.instance_variable_get(:@encoded_id)
  end

  def test_encoded_id_is_recalculated_if_id_changes
    initial_encoded_id = model.encoded_id
    model.id = model.id + 1
    new_encoded_id = model.encoded_id
    refute_equal initial_encoded_id, new_encoded_id
    assert_equal new_encoded_id, model.instance_variable_get(:@encoded_id)
  end

  def test_it_does_not_slug_encoded_id_for_model_with_no_slug
    assert_raises(StandardError) do
      EncodedId::Rails.configuration.slug_value_method_name = :name_for_encoded_id_slug
      model.slugged_encoded_id
    end
  end

  def test_slugged_encoded_id_is_memoized
    encoded_id = model.slugged_encoded_id
    assert_equal encoded_id, model.instance_variable_get(:@slugged_encoded_id)
  end

  def test_slugged_encoded_id_is_recalculated_if_id_changes
    initial_encoded_id = model.slugged_encoded_id
    model.id = model.id + 1
    new_encoded_id = model.slugged_encoded_id
    refute_equal initial_encoded_id, new_encoded_id
    assert_equal new_encoded_id, model.instance_variable_get(:@slugged_encoded_id)
  end

  def test_it_gets_slugged_encoded_id_for_model_with_custom_slug_and_annotation
    assert_equal "sluggy--my_model_#{model.encoded_id_hash}", model.slugged_encoded_id
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
