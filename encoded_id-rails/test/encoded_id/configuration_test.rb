# frozen_string_literal: true

require "test_helper"

class EncodedId::ConfigurationTest < Minitest::Test
  def setup
    # Reset configuration to defaults before each test
    @config = EncodedId::Rails::Configuration.new
    # Store original configuration
    @original_config = EncodedId::Rails.configuration
    # Use our test configuration
    EncodedId::Rails.instance_variable_set(:@configuration, @config)
  end
  
  def teardown
    # Restore original configuration
    EncodedId::Rails.instance_variable_set(:@configuration, @original_config)
  end
  
  # Tests moved from rails_test.rb
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
  
  # New tests for Configuration
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
    # Get a character from the alphabet
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
    # Should not raise
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
  end
end