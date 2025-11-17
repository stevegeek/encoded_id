# frozen_string_literal: true

require "test_helper"

class EncodedId::Rails::EncoderMethodsTest < Minitest::Test
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

  def test_it_gets_encoded_id_with_options_with_nil_separator
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

  def test_it_encodes_with_custom_encoder
    # Only run if Sqids is available

    require "sqids"

    # Store original config
    original_encoder = EncodedId::Rails.configuration.encoder

    # Set encoder to sqids
    config = EncodedId::Rails.configuration
    config.encoder = :sqids

    # Encode with sqids
    sqids_encoded = MyModel.encode_encoded_id(model.id)
    assert_kind_of String, sqids_encoded

    # Should decode correctly
    assert_equal [model.id], MyModel.decode_encoded_id(sqids_encoded)

    # Reset to original encoder
    config.encoder = original_encoder
  rescue LoadError
    skip "Sqids gem not available"
  end

  def test_it_encodes_with_hashids_and_blocklist
    # Store original config
    original_blocklist = EncodedId::Rails.configuration.blocklist
    original_encoder = EncodedId::Rails.configuration.encoder

    # Set encoder to hashids
    config = EncodedId::Rails.configuration
    config.encoder = :hashids

    # First, get an encoded ID without blocklist
    first_encoded = MyModel.encode_encoded_id(model.id)

    # Now use the first 3 characters as blocklist word
    blocklist_word = first_encoded[0, 3]
    config.blocklist = [blocklist_word]

    # With HashIds, encoding the same ID with a blocklist that contains
    # part of the encoded ID should raise an error
    assert_raises(EncodedId::BlocklistError) do
      MyModel.encode_encoded_id(model.id)
    end

    # Reset to original config
    config.encoder = original_encoder
    config.blocklist = original_blocklist
  end

  def test_it_encodes_with_sqids_and_blocklist
    # Skip if Sqids not available
    begin
      require "sqids"
    rescue LoadError
      skip "Sqids gem not available"
      return
    end

    # Store original config
    original_blocklist = EncodedId::Rails.configuration.blocklist
    original_encoder = EncodedId::Rails.configuration.encoder

    # Set encoder to sqids
    config = EncodedId::Rails.configuration
    config.encoder = :sqids

    # First, get an encoded ID without blocklist
    first_encoded = MyModel.encode_encoded_id(model.id)
    assert_kind_of String, first_encoded

    # Now set a specific blocklist word that's common in encodings
    blocklist_word = "bad"
    config.blocklist = [blocklist_word]

    # With Sqids, encoding should succeed with blocklisted words
    # because Sqids automatically avoids them
    second_encoded = MyModel.encode_encoded_id(model.id)
    assert_kind_of String, second_encoded

    # Verify the blocklisted word doesn't appear in the encoded ID
    refute_match(/bad/i, second_encoded)

    # Should decode correctly
    assert_equal [model.id], MyModel.decode_encoded_id(second_encoded)

    # Reset to original config
    config.encoder = original_encoder
    config.blocklist = original_blocklist
  end
end
