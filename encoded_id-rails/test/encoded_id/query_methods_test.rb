# frozen_string_literal: true

require "test_helper"

class EncodedId::QueryMethodsTest < Minitest::Test
  attr_reader :model

  def setup
    @model = MyModel.create
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
    # Check what decode_encoded_id returns
    result = MyModel.decode_encoded_id("foo")
    assert_equal [], result

    # Since decode_encoded_id returns an empty array and not nil, where_encoded_id
    # will not raise an exception but return an empty relation
    relation = MyModel.where_encoded_id("foo")
    assert_kind_of ActiveRecord::Relation, relation
    assert_equal [], relation.to_a
  end

  def test_where_encoded_id_with_invalid_character_encoded_id
    # Check what decode_encoded_id returns
    result = MyModel.decode_encoded_id("!@#$%%^&*()_+")
    assert_equal [], result

    # Since decode_encoded_id returns an empty array and not nil, where_encoded_id
    # will not raise an exception but return an empty relation
    relation = MyModel.where_encoded_id("!@#$%%^&*()_+")
    assert_kind_of ActiveRecord::Relation, relation
    assert_equal [], relation.to_a
  end

  def test_where_encoded_id_raises_with_nil_encoded_id
    # decode_encoded_id should return nil for nil input
    assert_nil MyModel.decode_encoded_id(nil)

    # where_encoded_id should raise because decode_encoded_id returned nil
    assert_raises(ActiveRecord::RecordNotFound) do
      MyModel.where_encoded_id(nil)
    end
  end

  def test_where_encoded_id_raises_with_empty_encoded_id
    # decode_encoded_id should return nil for empty string input
    assert_nil MyModel.decode_encoded_id("")

    # where_encoded_id should raise because decode_encoded_id returned nil
    assert_raises(ActiveRecord::RecordNotFound) do
      MyModel.where_encoded_id("")
    end
  end
end
