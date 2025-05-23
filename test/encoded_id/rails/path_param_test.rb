# frozen_string_literal: true

require "test_helper"

class EncodedId::Rails::PathParamTest < Minitest::Test
  def setup
    @model_with_path_param = ModelWithPathParam.create(name: "bar", foo: "bar")
    @model_with_slugged_path_param = ModelWithSluggedPathParam.create(name: "baz", foo: "baz")
  end

  def test_to_param_returns_encoded_id_for_model_with_path_param
    assert_equal @model_with_path_param.encoded_id, @model_with_path_param.to_param
  end

  def test_to_param_returns_slugged_encoded_id_for_model_with_slugged_path_param
    assert_equal @model_with_slugged_path_param.slugged_encoded_id, @model_with_slugged_path_param.to_param
  end

  def test_to_param_raises_if_no_encoded_id_for_model_with_path_param
    model = ModelWithPathParam.new
    assert_raises(StandardError, /Cannot create path param/) do
      model.to_param
    end
  end

  def test_to_param_raises_if_no_encoded_id_for_model_with_slugged_path_param
    model = ModelWithSluggedPathParam.new
    assert_raises(StandardError, /Cannot create path param/) do
      model.to_param
    end
  end

  def test_to_param_includes_slug_in_model_with_slugged_path_param
    EncodedId::Rails.configuration.slug_value_method_name = :custom_slug_method
    assert_match(/^custom-slug--/, @model_with_slugged_path_param.to_param)
    EncodedId::Rails.configuration.slug_value_method_name = :name_for_encoded_id_slug
  end
end
