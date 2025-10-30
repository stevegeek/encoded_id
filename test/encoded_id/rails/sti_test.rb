# frozen_string_literal: true

require "test_helper"

class EncodedId::Rails::StiTest < Minitest::Test
  def setup
    @parent = StiRecord.create(name: "Parent")
    @child = StiChild.create(name: "Child")
    @grandchild = StiGrandchild.create(name: "Grandchild")
    @child_with_shared_salt = StiChildWithSharedSalt.create(name: "Child with shared salt")
  end

  def test_sti_models_have_different_salts_by_default
    parent_salt = StiRecord.encoded_id_salt
    child_salt = StiChild.encoded_id_salt
    grandchild_salt = StiGrandchild.encoded_id_salt

    refute_equal parent_salt, child_salt
    refute_equal parent_salt, grandchild_salt
    refute_equal child_salt, grandchild_salt
  end

  def test_sti_models_generate_different_encoded_ids_for_same_record_id
    parent = StiRecord.create(name: "Test")
    # Even if they had the same ID, their encoded IDs would be different
    # because they use different salts
    parent_encoded = StiRecord.encode_encoded_id(parent.id)
    child_encoded = StiChild.encode_encoded_id(parent.id)

    refute_equal parent_encoded, child_encoded
  end

  def test_parent_cannot_decode_child_encoded_id_by_default
    child_encoded_id = @child.encoded_id
    decoded_ids = StiRecord.decode_encoded_id(child_encoded_id)
    refute_includes decoded_ids, @child.id
  end

  def test_child_cannot_decode_parent_encoded_id_by_default
    parent_encoded_id = @parent.encoded_id
    decoded_ids = StiChild.decode_encoded_id(parent_encoded_id)
    refute_includes decoded_ids, @parent.id
  end

  def test_find_by_encoded_id_does_not_work_across_sti_hierarchy_by_default
    child_encoded_id = @child.encoded_id
    result = StiRecord.find_by_encoded_id(child_encoded_id)
    refute_equal @child, result
  end

  def test_where_encoded_id_does_not_work_across_sti_hierarchy_by_default
    child_encoded_id = @child.encoded_id
    results = StiRecord.where_encoded_id(child_encoded_id).to_a
    refute_includes results, @child
  end

  def test_shared_salt_allows_cross_class_decoding
    # Models with shared salt can decode each other's IDs
    parent_salt = StiRecord.encoded_id_salt
    child_shared_salt = StiChildWithSharedSalt.encoded_id_salt
    another_child_shared_salt = AnotherStiChildWithSharedSalt.encoded_id_salt

    assert_equal parent_salt, child_shared_salt
    assert_equal parent_salt, another_child_shared_salt
  end

  def test_shared_salt_encoded_ids_are_interchangeable
    test_id = @child_with_shared_salt.id
    parent_encoded = StiRecord.encode_encoded_id(test_id)
    child_encoded = StiChildWithSharedSalt.encode_encoded_id(test_id)
    assert_equal parent_encoded, child_encoded
  end

  def test_shared_salt_allows_parent_to_decode_child_id
    child_encoded_id = @child_with_shared_salt.encoded_id
    decoded_ids = StiRecord.decode_encoded_id(child_encoded_id)
    assert_includes decoded_ids, @child_with_shared_salt.id
  end

  def test_shared_salt_allows_child_to_decode_parent_id
    parent_encoded_id = @parent.encoded_id
    decoded_ids = StiChildWithSharedSalt.decode_encoded_id(parent_encoded_id)
    assert_includes decoded_ids, @parent.id
  end

  def test_shared_salt_find_by_encoded_id_works_across_hierarchy
    child_encoded_id = @child_with_shared_salt.encoded_id
    result = StiRecord.find_by_encoded_id(child_encoded_id)

    assert_equal @child_with_shared_salt, result
  end

  def test_shared_salt_where_encoded_id_works_across_hierarchy
    child_encoded_id = @child_with_shared_salt.encoded_id
    results = StiRecord.where_encoded_id(child_encoded_id).to_a
    assert_includes results, @child_with_shared_salt
    assert_equal 1, results.size
  end

  def test_siblings_with_shared_salt_can_decode_each_others_ids
    child1_encoded = @child_with_shared_salt.encoded_id
    decoded_ids = AnotherStiChildWithSharedSalt.decode_encoded_id(child1_encoded)
    assert_includes decoded_ids, @child_with_shared_salt.id
  end

  def test_annotation_differs_by_class_in_sti_hierarchy
    parent_annotation = @parent.annotation_for_encoded_id
    child_annotation = @child.annotation_for_encoded_id
    grandchild_annotation = @grandchild.annotation_for_encoded_id

    assert_equal "sti_record", parent_annotation
    assert_equal "sti_child", child_annotation
    assert_equal "sti_grandchild", grandchild_annotation
  end
end
