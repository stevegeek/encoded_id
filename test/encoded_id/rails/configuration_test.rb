# frozen_string_literal: true

require "test_helper"

class EncodedId::Rails::ConfigurationTest < Minitest::Test
  def setup
    @config = EncodedId::Rails::Configuration.new
    @original_config = EncodedId::Rails.configuration
    EncodedId::Rails.instance_variable_set(:@configuration, @config)
  end

  def teardown
    EncodedId::Rails.instance_variable_set(:@configuration, @original_config)
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

  def test_slugged_id_separator_cannot_be_blank
    error = assert_raises ArgumentError do
      EncodedId::Rails.configuration.slugged_id_separator = ""
    end

    assert_match(/must not be part of the alphabet/, error.message)
  end

  def test_slugged_id_separator_cannot_be_same_as_group_separator
    EncodedId::Rails.configuration.group_separator = "+"

    error = assert_raises ArgumentError do
      EncodedId::Rails.configuration.slugged_id_separator = "+"
    end

    assert_match(/same as the group separator/, error.message)
  end

  def test_annotated_id_separator_cannot_be_blank
    error = assert_raises ArgumentError do
      EncodedId::Rails.configuration.annotated_id_separator = ""
    end

    assert_match(/must not be part of the alphabet/, error.message)
  end

  def test_annotated_id_separator_cannot_be_same_as_group_separator
    EncodedId::Rails.configuration.group_separator = "+"

    error = assert_raises ArgumentError do
      EncodedId::Rails.configuration.annotated_id_separator = "+"
    end

    assert_match(/same as the group separator/, error.message)
  end

  def test_separator_with_characters_in_alphabet
    alphabet_char = EncodedId::Rails.configuration.alphabet.to_s[0]

    error = assert_raises ArgumentError do
      EncodedId::Rails.configuration.slugged_id_separator = alphabet_char
    end

    assert_match(/must not be part of the alphabet/, error.message)

    error = assert_raises ArgumentError do
      EncodedId::Rails.configuration.annotated_id_separator = alphabet_char
    end

    assert_match(/must not be part of the alphabet/, error.message)

    error = assert_raises ArgumentError do
      EncodedId::Rails.configuration.group_separator = alphabet_char
    end

    assert_match(/must not be part of the alphabet/, error.message)
  end

  def test_valid_separators_accepted
    EncodedId::Rails.configuration.group_separator = "#"
    EncodedId::Rails.configuration.slugged_id_separator = "***"
    EncodedId::Rails.configuration.annotated_id_separator = "^"

    assert_equal "#", EncodedId::Rails.configuration.group_separator
    assert_equal "***", EncodedId::Rails.configuration.slugged_id_separator
    assert_equal "^", EncodedId::Rails.configuration.annotated_id_separator
  end

  def test_default_configuration_values
    config = EncodedId::Rails::Configuration.new

    assert_equal 4, config.character_group_size
    assert_equal "-", config.group_separator
    assert_equal 8, config.id_length
    assert_equal :name_for_encoded_id_slug, config.slug_value_method_name
    assert_equal "--", config.slugged_id_separator
    assert_equal :annotation_for_encoded_id, config.annotation_method_name
    assert_equal "_", config.annotated_id_separator
    assert_equal false, config.model_to_param_returns_encoded_id
    assert_equal :sqids, config.encoder
    assert_equal false, config.downcase_on_decode
    assert_instance_of EncodedId::Blocklist, config.blocklist
    assert config.blocklist.empty?
  end

  def test_encoder_validation
    EncodedId::Rails.configuration.encoder = :sqids
    assert_equal :sqids, EncodedId::Rails.configuration.encoder

    EncodedId::Rails.configuration.encoder = :hashids
    assert_equal :hashids, EncodedId::Rails.configuration.encoder

    assert_raises ArgumentError do
      EncodedId::Rails.configuration.encoder = :invalid_encoder
    end
  end

  def test_blocklist_setting
    blocklist = ["bad", "word"]
    EncodedId::Rails.configuration.blocklist = blocklist
    assert_equal blocklist, EncodedId::Rails.configuration.blocklist

    blocklist_set = Set.new(["bad", "word"])
    EncodedId::Rails.configuration.blocklist = blocklist_set
    assert_equal blocklist_set, EncodedId::Rails.configuration.blocklist

    EncodedId::Rails.configuration.blocklist = nil
    assert_nil EncodedId::Rails.configuration.blocklist
  end
end
