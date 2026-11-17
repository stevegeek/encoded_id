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
      EncodedId::Rails.configure { |config| config.group_separator = "a" }
    end
  end

  def test_configuration_prevents_invalid_slugged_id_separator
    assert_raises ArgumentError do
      EncodedId::Rails.configure { |config| config.slugged_id_separator = "a" }
    end
    assert_raises ArgumentError do
      EncodedId::Rails.configure do |config|
        config.group_separator = "-"
        config.slugged_id_separator = "-"
      end
    end
  end

  def test_configuration_prevents_invalid_annotated_id_separator
    assert_raises ArgumentError do
      EncodedId::Rails.configure { |config| config.annotated_id_separator = "a" }
    end
  end

  def test_slugged_id_separator_cannot_be_blank
    error = assert_raises ArgumentError do
      EncodedId::Rails.configure { |config| config.slugged_id_separator = "" }
    end

    assert_match(/must not be part of the alphabet/, error.message)
  end

  def test_slugged_id_separator_cannot_be_same_as_group_separator
    error = assert_raises ArgumentError do
      EncodedId::Rails.configure do |config|
        config.group_separator = "+"
        config.slugged_id_separator = "+"
      end
    end

    assert_match(/same as the group separator/, error.message)
  end

  def test_annotated_id_separator_cannot_be_blank
    error = assert_raises ArgumentError do
      EncodedId::Rails.configure { |config| config.annotated_id_separator = "" }
    end

    assert_match(/must not be part of the alphabet/, error.message)
  end

  def test_annotated_id_separator_cannot_be_same_as_group_separator
    error = assert_raises ArgumentError do
      EncodedId::Rails.configure do |config|
        config.group_separator = "+"
        config.annotated_id_separator = "+"
      end
    end

    assert_match(/same as the group separator/, error.message)
  end

  def test_separator_with_characters_in_alphabet
    alphabet_char = EncodedId::Rails.configuration.alphabet.to_s[0]

    [:slugged_id_separator, :annotated_id_separator, :group_separator].each do |setting|
      error = assert_raises ArgumentError do
        EncodedId::Rails.configure { |config| config.public_send(:"#{setting}=", alphabet_char) }
      end

      assert_match(/must not be part of the alphabet/, error.message)
    end
  end

  def test_separator_setters_do_not_validate_until_configure_finishes
    config = EncodedId::Rails::Configuration.new
    config.group_separator = "a"

    assert_equal "a", config.group_separator
    assert_raises(ArgumentError) { config.validate! }
  end

  def test_failed_configure_keeps_the_previous_configuration
    previous = EncodedId::Rails.configuration

    assert_raises ArgumentError do
      EncodedId::Rails.configure { |config| config.group_separator = "a" }
    end

    assert_same previous, EncodedId::Rails.configuration
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
    assert_equal 128, config.max_length
    assert_equal 32, config.max_inputs_per_id
    assert_equal 4, config.hex_digit_encoding_group_size
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

  def test_max_length_setting
    EncodedId::Rails.configuration.max_length = 64
    assert_equal 64, EncodedId::Rails.configuration.max_length

    EncodedId::Rails.configuration.max_length = nil
    assert_nil EncodedId::Rails.configuration.max_length
  end

  def test_max_inputs_per_id_setting
    EncodedId::Rails.configuration.max_inputs_per_id = 16
    assert_equal 16, EncodedId::Rails.configuration.max_inputs_per_id
  end

  def test_hex_digit_encoding_group_size_setting
    EncodedId::Rails.configuration.hex_digit_encoding_group_size = 8
    assert_equal 8, EncodedId::Rails.configuration.hex_digit_encoding_group_size
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

  def test_configure_freezes_the_configuration
    EncodedId::Rails.configure { |config| config.id_length = 10 }

    assert_predicate EncodedId::Rails.configuration, :frozen?
    assert_equal 10, EncodedId::Rails.configuration.id_length
    assert_raises(FrozenError) { EncodedId::Rails.configuration.id_length = 12 }
  end

  def test_configure_replaces_the_configuration_object
    before = EncodedId::Rails.configuration
    EncodedId::Rails.configure { |config| config.id_length = 10 }

    refute_same before, EncodedId::Rails.configuration
  end

  def test_configure_without_a_block_returns_the_current_configuration
    assert_same EncodedId::Rails.configuration, EncodedId::Rails.configure
  end

  def test_configure_rejects_an_alphabet_that_contains_the_group_separator
    assert_raises ArgumentError do
      EncodedId::Rails.configure do |config|
        config.group_separator = "+"
        config.alphabet = EncodedId::Alphabet.new("0123456789abcdef+")
      end
    end
    assert_equal "-", EncodedId::Rails.configuration.group_separator
  end

  def test_default_configuration_is_frozen
    EncodedId::Rails.instance_variable_set(:@configuration, nil)

    assert_predicate EncodedId::Rails.configuration, :frozen?
  end
end
