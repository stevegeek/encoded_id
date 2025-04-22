# frozen_string_literal: true

require "test_helper"

class EncodedId::AnnotatedIdTest < Minitest::Test
  def test_annotated_id_with_valid_inputs
    annotated_id = EncodedId::Rails::AnnotatedId.new(
      annotation: "user",
      id_part: "abc123",
      separator: "_"
    )

    result = annotated_id.annotated_id

    assert_equal "user_abc123", result
  end

  def test_annotated_id_with_complex_annotation
    annotated_id = EncodedId::Rails::AnnotatedId.new(
      annotation: "User Profile",
      id_part: "abc123",
      separator: "_"
    )

    result = annotated_id.annotated_id

    assert_equal "user-profile_abc123", result
  end

  def test_annotated_id_with_blank_id_part
    annotated_id = EncodedId::Rails::AnnotatedId.new(
      annotation: "user",
      id_part: "",
      separator: "_"
    )

    error = assert_raises(StandardError) do
      annotated_id.annotated_id
    end

    assert_match(/not provide a valid ID/, error.message)
  end

  def test_annotated_id_with_nil_id_part
    annotated_id = EncodedId::Rails::AnnotatedId.new(
      annotation: "user",
      id_part: nil,
      separator: "_"
    )

    error = assert_raises(StandardError) do
      annotated_id.annotated_id
    end

    assert_match(/not provide a valid ID/, error.message)
  end

  def test_annotated_id_with_blank_annotation
    annotated_id = EncodedId::Rails::AnnotatedId.new(
      annotation: "",
      id_part: "abc123",
      separator: "_"
    )

    error = assert_raises(StandardError) do
      annotated_id.annotated_id
    end

    assert_match(/not provide a valid ID and\/or annotation/, error.message)
  end

  def test_annotated_id_with_nil_annotation
    annotated_id = EncodedId::Rails::AnnotatedId.new(
      annotation: nil,
      id_part: "abc123",
      separator: "_"
    )

    error = assert_raises(StandardError) do
      annotated_id.annotated_id
    end

    assert_match(/not provide a valid ID and\/or annotation/, error.message)
  end

  def test_annotated_id_with_custom_separator
    annotated_id = EncodedId::Rails::AnnotatedId.new(
      annotation: "user",
      id_part: "abc123",
      separator: "^"
    )

    result = annotated_id.annotated_id

    assert_equal "user%5Eabc123", result  # "^" is URL-encoded to %5E
  end
end
