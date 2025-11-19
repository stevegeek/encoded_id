# frozen_string_literal: true

require "test_helper"

class EncodedId::Rails::AutoPathParamHashidsTest < Minitest::Test
  def test_to_param_returns_encoded_id_when_auto_include_enabled
    @original_config = EncodedId::Rails.configuration

    @config = EncodedId::Rails::Configuration.new
    @config.salt = "1234"
    @config.encoder = :hashids
    @config.model_to_param_returns_encoded_id = true

    EncodedId::Rails.instance_variable_set(:@configuration, @config)

    # Reload model to pick up new configuration
    Object.send(:remove_const, :AutoPathParamModel) if Object.const_defined?(:AutoPathParamModel)
    load File.expand_path("../../support/auto_path_param_model.rb", __dir__)

    @model = AutoPathParamModel.create(foo: "bar")

    assert_equal @model.encoded_id, @model.to_param

    EncodedId::Rails.instance_variable_set(:@configuration, @original_config)
  end

  def test_to_param_with_config_disabled
    @original_config = EncodedId::Rails.configuration

    EncodedId::Rails.configure do |config|
      config.encoder = :hashids
    end

    model = MyModel.create(foo: "bar")

    assert_equal model.id.to_s, model.to_param
    refute_includes MyModel.included_modules, EncodedId::Rails::PathParam

    EncodedId::Rails.instance_variable_set(:@configuration, @original_config)
  end
end
