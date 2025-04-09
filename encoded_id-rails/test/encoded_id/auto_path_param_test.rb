# frozen_string_literal: true

require "test_helper"

class EncodedId::AutoPathParamTest < Minitest::Test
  def test_to_param_returns_encoded_id_when_auto_include_enabled
    # Store original configuration
    @original_config = EncodedId::Rails.configuration

    # Create a new configuration with model_to_param_returns_encoded_id set to true
    @config = EncodedId::Rails::Configuration.new
    @config.salt = "1234"
    @config.model_to_param_returns_encoded_id = true

    # Apply this configuration
    EncodedId::Rails.instance_variable_set(:@configuration, @config)

    # Clear existing AutoPathParamModel class
    Object.send(:remove_const, :AutoPathParamModel) if Object.const_defined?(:AutoPathParamModel)

    # Load the auto path param model again with the new configuration
    load File.expand_path("../support/auto_path_param_model.rb", __dir__)

    @model = AutoPathParamModel.create(foo: "bar")

    assert_equal @model.encoded_id, @model.to_param

    # Restore original configuration
    EncodedId::Rails.instance_variable_set(:@configuration, @original_config)
  end

  def test_to_param_with_config_disabled
    model = MyModel.create(foo: "bar")

    # The default to_param should be used (returning id.to_s)
    assert_equal model.id.to_s, model.to_param

    # The model should NOT have PathParam included automatically
    refute_includes MyModel.included_modules, EncodedId::Rails::PathParam
  end
end
