# frozen_string_literal: true

require "test_helper"

class EncodedId::FinderMethodsTest < Minitest::Test
  attr_reader :model

  def setup
    # Store the original configuration
    @original_config = EncodedId::Rails.configuration
    @model = MyModel.create
  end

  def teardown
    # Restore the original configuration
    EncodedId::Rails.instance_variable_set(:@configuration, @original_config)
  end

  # Tests moved from rails_test.rb
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
end
