# frozen_string_literal: true

require "test_helper"

class EncodedId::Rails::QueryMethodsHashidsTest < Minitest::Test
  attr_reader :model

  def setup
    @original_config = EncodedId::Rails.configuration

    EncodedId::Rails.configure do |config|
      config.encoder = :hashids
    end

    @model = MyModel.create
  end

  def teardown
    EncodedId::Rails.instance_variable_set(:@configuration, @original_config)
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

  # Tests for undecodable encoded IDs
  def test_where_encoded_id_with_undecodable_encoded_id
    result = MyModel.decode_encoded_id("foo$bar!")
    assert_equal [], result

    relation = MyModel.where_encoded_id("foo$bar!")
    assert_kind_of ActiveRecord::Relation, relation
    assert_equal [], relation.to_a
  end

  def test_where_encoded_id_with_invalid_character_encoded_id
    result = MyModel.decode_encoded_id("!@#$%%^&*()_+")
    assert_equal [], result

    relation = MyModel.where_encoded_id("!@#$%%^&*()_+")
    assert_kind_of ActiveRecord::Relation, relation
    assert_equal [], relation.to_a
  end

  def test_where_encoded_id_raises_with_nil_encoded_id
    assert_nil MyModel.decode_encoded_id(nil)

    assert_raises(ActiveRecord::RecordNotFound) do
      MyModel.where_encoded_id(nil)
    end
  end

  def test_where_encoded_id_raises_with_empty_encoded_id
    assert_nil MyModel.decode_encoded_id("")

    assert_raises(ActiveRecord::RecordNotFound) do
      MyModel.where_encoded_id("")
    end
  end

  # Tests for multiple encoded IDs
  def test_where_encoded_id_with_multiple_arguments
    model2 = MyModel.create
    model3 = MyModel.create

    result = MyModel.where_encoded_id(model.encoded_id, model2.encoded_id, model3.encoded_id).to_a
    assert_equal 3, result.size
    assert_includes result, model
    assert_includes result, model2
    assert_includes result, model3
  end

  def test_where_encoded_id_with_array_of_encoded_ids
    model2 = MyModel.create
    model3 = MyModel.create

    encoded_ids = [model.encoded_id, model2.encoded_id, model3.encoded_id]
    result = MyModel.where_encoded_id(encoded_ids).to_a
    assert_equal 3, result.size
    assert_includes result, model
    assert_includes result, model2
    assert_includes result, model3
  end

  def test_where_encoded_id_with_multiple_args_some_with_slugs
    model2 = MyModel.create
    result = MyModel.where_encoded_id("slug1--#{model.encoded_id}", "slug2--#{model2.encoded_id}").to_a
    assert_equal 2, result.size
    assert_includes result, model
    assert_includes result, model2
  end

  def test_where_encoded_id_with_nested_arrays
    model2 = MyModel.create
    result = MyModel.where_encoded_id([[model.encoded_id], [model2.encoded_id]]).to_a
    assert_equal 2, result.size
    assert_includes result, model
    assert_includes result, model2
  end

  def test_where_encoded_id_raises_when_any_id_is_nil_in_multiple
    model2 = MyModel.create
    assert_raises(ActiveRecord::RecordNotFound) do
      MyModel.where_encoded_id(model.encoded_id, nil, model2.encoded_id)
    end
  end

  def test_where_encoded_id_raises_when_empty_array_provided
    assert_raises(ActiveRecord::RecordNotFound) do
      MyModel.where_encoded_id([])
    end
  end
end
