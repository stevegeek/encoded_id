# frozen_string_literal: true

require "test_helper"

class EncodedId::Rails::StiSqidsTest < Minitest::Test
  def setup
    @original_config = EncodedId::Rails.configuration
    EncodedId::Rails.instance_variable_set(:@configuration, @original_config.dup)

    EncodedId::Rails.configure do |config|
      config.encoder = :sqids
    end

    @parent = StiRecord.create(name: "Parent")
    @child = StiChild.create(name: "Child")
    @grandchild = StiGrandchild.create(name: "Grandchild")
    @child_with_own_alphabet = StiChildWithOwnAlphabet.create(name: "Child with own alphabet")
  end

  def teardown
    EncodedId::Rails.instance_variable_set(:@configuration, @original_config)
  end

  def test_sqids_is_the_default_encoder
    assert_equal :sqids, EncodedId::Rails::Configuration.new.encoder
  end

  def test_sti_models_have_different_salts
    refute_equal StiRecord.encoded_id_salt, StiChild.encoded_id_salt
    refute_equal StiChild.encoded_id_salt, StiGrandchild.encoded_id_salt
  end

  def test_sti_models_generate_the_same_encoded_id_for_the_same_record_id
    parent_encoded = StiRecord.encode_encoded_id(@parent.id)

    assert_equal parent_encoded, StiChild.encode_encoded_id(@parent.id)
    assert_equal parent_encoded, StiGrandchild.encode_encoded_id(@parent.id)
  end

  def test_parent_decodes_child_encoded_id
    assert_equal [@child.id], StiRecord.decode_encoded_id(@child.encoded_id)
  end

  def test_child_decodes_parent_encoded_id
    assert_equal [@parent.id], StiChild.decode_encoded_id(@parent.encoded_id)
  end

  def test_find_by_encoded_id_works_across_sti_hierarchy
    assert_equal @child, StiRecord.find_by_encoded_id(@child.encoded_id)
  end

  def test_where_encoded_id_works_across_sti_hierarchy
    results = StiRecord.where_encoded_id(@child.encoded_id).to_a

    assert_equal [@child], results
  end

  def test_child_finder_still_scopes_to_child_type
    assert_nil StiChild.find_by_encoded_id(@parent.encoded_id)
  end

  def test_annotation_differs_by_class_in_sti_hierarchy
    assert_match(/\Asti_record_/, @parent.encoded_id)
    assert_match(/\Asti_child_/, @child.encoded_id)
    assert_match(/\Asti_grandchild_/, @grandchild.encoded_id)
  end

  def test_annotation_is_not_checked_on_lookup
    child_hash = @child.encoded_id.delete_prefix("sti_child_")

    assert_equal @child, StiRecord.find_by_encoded_id("sti_grandchild_#{child_hash}")
    assert_equal @child, StiRecord.find_by_encoded_id("anything_#{child_hash}")
  end

  def test_encoded_id_of_another_model_resolves_a_record_with_the_same_id
    other_model_encoded_id = "my_model_#{MyModel.encode_encoded_id(@parent.id)}"

    assert_equal @parent, StiRecord.find_by_encoded_id(other_model_encoded_id)
  end

  def test_own_alphabet_generates_a_different_hash_for_the_same_record_id
    refute_equal StiRecord.encode_encoded_id(@child_with_own_alphabet.id),
      StiChildWithOwnAlphabet.encode_encoded_id(@child_with_own_alphabet.id)
  end

  def test_parent_does_not_decode_own_alphabet_child_encoded_id_to_the_same_id
    decoded_ids = StiRecord.decode_encoded_id(@child_with_own_alphabet.encoded_id)

    refute_includes decoded_ids, @child_with_own_alphabet.id
  end

  def test_own_alphabet_child_round_trips_its_encoded_id
    assert_equal @child_with_own_alphabet,
      StiChildWithOwnAlphabet.find_by_encoded_id(@child_with_own_alphabet.encoded_id)
  end
end
