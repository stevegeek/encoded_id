# frozen_string_literal: true

require "test_helper"

class EncodedId::Rails::EncoderMethodsTest < Minitest::Test
  attr_reader :model

  def setup
    @original_config = EncodedId::Rails.configuration
    @model = MyModel.create
  end

  def teardown
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
    with_encoded_id_config(encoder: :sqids) do
      sqids_encoded = MyModel.encode_encoded_id(model.id)
      assert_kind_of String, sqids_encoded

      assert_equal [model.id], MyModel.decode_encoded_id(sqids_encoded)
    end
  end

  def test_it_encodes_with_hashids_and_blocklist
    with_encoded_id_config(encoder: :hashids) do
      first_encoded = MyModel.encode_encoded_id(model.id)

      blocklist_word = first_encoded[0, 3]
      with_encoded_id_config(blocklist: [blocklist_word]) do
        # With HashIds, encoding the same ID with a blocklist that contains
        # part of the encoded ID should raise an error
        assert_raises(EncodedId::BlocklistError) do
          MyModel.encode_encoded_id(model.id)
        end
      end
    end
  end

  def test_it_encodes_with_sqids_and_blocklist
    with_encoded_id_config(encoder: :sqids) do
      first_encoded = MyModel.encode_encoded_id(model.id)
      assert_kind_of String, first_encoded

      with_encoded_id_config(blocklist: ["bad"]) do
        # With Sqids, encoding should succeed with blocklisted words
        # because Sqids automatically avoids them
        second_encoded = MyModel.encode_encoded_id(model.id)
        assert_kind_of String, second_encoded

        refute_match(/bad/i, second_encoded)
        assert_equal [model.id], MyModel.decode_encoded_id(second_encoded)
      end
    end
  end

  def test_it_encodes_with_max_length_option
    with_encoded_id_config(max_length: 64) do
      eid = MyModel.encode_encoded_id(model.id)
      assert_kind_of String, eid
      assert_equal [model.id], MyModel.decode_encoded_id(eid)
    end
  end

  def test_it_encodes_with_max_length_passed_as_option
    eid = MyModel.encode_encoded_id(model.id, {max_length: 32})
    assert_kind_of String, eid
    assert_equal [model.id], MyModel.decode_encoded_id(eid)
  end

  def test_it_encodes_with_nil_max_length_option
    # Test that nil max_length (no limit) works
    eid = MyModel.encode_encoded_id(model.id, {max_length: nil})
    assert_kind_of String, eid
    assert_equal [model.id], MyModel.decode_encoded_id(eid)
  end

  def test_it_encodes_with_max_inputs_per_id_option
    with_encoded_id_config(max_inputs_per_id: 16) do
      eid = MyModel.encode_encoded_id([1, 2, 3])
      assert_kind_of String, eid
      assert_equal [1, 2, 3], MyModel.decode_encoded_id(eid)
    end
  end

  def test_it_encodes_with_hex_digit_encoding_group_size_option
    with_encoded_id_config(hex_digit_encoding_group_size: 8) do
      eid = MyModel.encode_encoded_id(model.id)
      assert_kind_of String, eid
      assert_equal [model.id], MyModel.decode_encoded_id(eid)
    end
  end

  def test_max_length_enforced_raises_when_exceeded
    # Set a very small max_length that will be exceeded by encoding a large number
    with_encoded_id_config(encoder: :sqids, max_length: 4) do
      # Encoding a large array should cause the encoded id to exceed max_length
      assert_raises(EncodedId::EncodedIdLengthError) do
        MyModel.encode_encoded_id([1, 2, 3, 4, 5, 6, 7, 8, 9, 10])
      end
    end
  end

  def test_max_inputs_per_id_enforced_raises_when_exceeded
    with_encoded_id_config(encoder: :sqids, max_inputs_per_id: 3) do
      # Encoding more ids than allowed should raise
      assert_raises(EncodedId::InvalidInputError) do
        MyModel.encode_encoded_id([1, 2, 3, 4])
      end
    end
  end

  def test_repeated_encode_and_decode_reuse_the_coder
    eid = MyModel.encode_encoded_id(model.id)

    calls = count_reversible_id_builds do
      assert_equal eid, MyModel.encode_encoded_id(model.id)
      assert_equal [model.id], MyModel.decode_encoded_id(eid)
    end

    assert_equal 0, calls
    assert_same MyModel.encoded_id_coder, MyModel.encoded_id_coder
  end

  def test_coder_is_not_cached_when_call_time_options_are_given
    refute_same MyModel.encoded_id_coder(character_group_size: 2), MyModel.encoded_id_coder(character_group_size: 2)
    refute_same MyModel.encoded_id_coder, MyModel.encoded_id_coder(character_group_size: 2)
    assert_match(/\A[a-z0-9]{4}-[a-z0-9]{4}\z/, MyModel.encode_encoded_id(model.id))
  end

  def test_coder_is_reused_until_the_configuration_is_replaced
    coder = MyModel.encoded_id_coder
    assert_same coder, MyModel.encoded_id_coder

    with_encoded_id_config(group_separator: "+", id_length: 12) do
      refute_same coder, MyModel.encoded_id_coder
      eid = MyModel.encode_encoded_id(model.id)
      assert_match(/\A[a-z0-9]{4}\+[a-z0-9]{4}\+[a-z0-9]{4}\z/, eid)
      assert_equal [model.id], MyModel.decode_encoded_id(eid)
    end

    assert_match(/\A[a-z0-9]{4}-[a-z0-9]{4}\z/, MyModel.encode_encoded_id(model.id))
  end

  def test_salt_change_through_configure_gives_new_ids
    with_encoded_id_config(encoder: :hashids) do
      eid = MyModel.encode_encoded_id(model.id)

      with_encoded_id_config(salt: "a-different-salt") do
        refute_equal eid, MyModel.encode_encoded_id(model.id)
      end
    end
  end

  def test_configuration_cannot_be_changed_outside_configure
    assert_raises(FrozenError) do
      EncodedId::Rails.configuration.salt = "a-different-salt"
    end
  end

  def test_sti_subclasses_with_different_salts_do_not_share_a_coder
    with_encoded_id_config(encoder: :hashids) do
      record = StiRecord.create(name: "Parent")
      parent_eid = StiRecord.encode_encoded_id(record.id)
      child_eid = StiChild.encode_encoded_id(record.id)

      refute_equal parent_eid, child_eid
      refute_same StiRecord.encoded_id_coder, StiChild.encoded_id_coder
      assert_equal parent_eid, StiRecord.encode_encoded_id(record.id)
      assert_equal child_eid, StiChild.encode_encoded_id(record.id)
    end
  end

  def test_coder_is_rebuilt_when_model_options_change_after_first_use
    klass = named_model_class(StiRecord, "LateConfiguredRecord")
    record = StiRecord.create(name: "Record")
    default_eid = klass.encode_encoded_id(record.id)

    klass.encoded_id_config(character_group_size: 2)

    eid = klass.encode_encoded_id(record.id)
    refute_equal default_eid, eid
    assert_match(/\A([a-z0-9]{2}-){3}[a-z0-9]{2}\z/, eid)
    assert_equal [record.id], klass.decode_encoded_id(eid)
  end

  def test_subclass_coder_follows_parent_options_changed_after_first_use
    parent = named_model_class(StiRecord, "LateConfiguredParent")
    child = named_model_class(parent, "LateConfiguredChild")
    record = StiRecord.create(name: "Record")
    default_eid = child.encode_encoded_id(record.id)

    parent.encoded_id_config(character_group_size: 2)

    eid = child.encode_encoded_id(record.id)
    refute_equal default_eid, eid
    assert_match(/\A([a-z0-9]{2}-){3}[a-z0-9]{2}\z/, eid)
  end

  private

  def named_model_class(parent, name)
    Class.new(parent) { define_singleton_method(:name) { name } }
  end

  def count_reversible_id_builds
    calls = 0
    EncodedId::ReversibleId.define_singleton_method(:new) do |*args, **kwargs, &block|
      calls += 1
      super(*args, **kwargs, &block)
    end
    yield
    calls
  ensure
    EncodedId::ReversibleId.singleton_class.remove_method(:new)
  end
end
