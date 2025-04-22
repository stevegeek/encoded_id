# frozen_string_literal: true

require "test_helper"

class EncodedId::EncoderMethodsTest < Minitest::Test
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
end
