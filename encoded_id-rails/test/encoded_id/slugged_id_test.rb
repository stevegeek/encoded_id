# frozen_string_literal: true

require "test_helper"

class EncodedId::SluggedIdTest < Minitest::Test
  def test_slugged_id_with_valid_inputs
    slugged_id = EncodedId::Rails::SluggedId.new(
      slug_part: "my-product",
      id_part: "abc123",
      separator: "--"
    )

    result = slugged_id.slugged_id

    assert_equal "my-product--abc123", result
  end

  def test_slugged_id_with_complex_slug
    slugged_id = EncodedId::Rails::SluggedId.new(
      slug_part: "My Awesome Product!",
      id_part: "abc123",
      separator: "--"
    )

    result = slugged_id.slugged_id

    assert_equal "my-awesome-product--abc123", result
  end

  def test_slugged_id_with_blank_id_part
    slugged_id = EncodedId::Rails::SluggedId.new(
      slug_part: "my-product",
      id_part: "",
      separator: "--"
    )

    error = assert_raises(StandardError) do
      slugged_id.slugged_id
    end

    assert_match(/not return a valid ID/, error.message)
  end

  def test_slugged_id_with_nil_id_part
    slugged_id = EncodedId::Rails::SluggedId.new(
      slug_part: "my-product",
      id_part: nil,
      separator: "--"
    )

    error = assert_raises(StandardError) do
      slugged_id.slugged_id
    end

    assert_match(/not return a valid ID/, error.message)
  end

  def test_slugged_id_with_blank_slug_part
    slugged_id = EncodedId::Rails::SluggedId.new(
      slug_part: "",
      id_part: "abc123",
      separator: "--"
    )

    error = assert_raises(StandardError) do
      slugged_id.slugged_id
    end

    assert_match(/not return a valid ID and\/or slug/, error.message)
  end

  def test_slugged_id_with_nil_slug_part
    slugged_id = EncodedId::Rails::SluggedId.new(
      slug_part: nil,
      id_part: "abc123",
      separator: "--"
    )

    error = assert_raises(StandardError) do
      slugged_id.slugged_id
    end

    assert_match(/not return a valid ID and\/or slug/, error.message)
  end

  def test_slugged_id_with_custom_separator
    slugged_id = EncodedId::Rails::SluggedId.new(
      slug_part: "my-product",
      id_part: "abc123",
      separator: "***"
    )

    result = slugged_id.slugged_id

    assert_equal "my-product%2A%2A%2Aabc123", result  # "***" is URL-encoded to %2A%2A%2A
  end
end
