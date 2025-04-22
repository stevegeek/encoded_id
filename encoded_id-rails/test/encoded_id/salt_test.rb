# frozen_string_literal: true

require "test_helper"

class EncodedId::SaltTest < Minitest::Test
  def test_generate_with_valid_class_and_salt
    klass = MyModel
    salt = "valid-salt"
    salt_generator = EncodedId::Rails::Salt.new(klass, salt)

    result = salt_generator.generate!

    assert_equal "#{klass.name}/#{salt}", result
  end

  def test_raises_when_class_is_anonymous
    # Create an anonymous class
    anonymous_class = Class.new
    salt = "valid-salt"
    salt_generator = EncodedId::Rails::Salt.new(anonymous_class, salt)

    error = assert_raises(StandardError) do
      salt_generator.generate!
    end

    assert_match(/must have a `name`/, error.message)
  end

  def test_raises_when_salt_is_nil
    klass = MyModel
    salt = nil
    salt_generator = EncodedId::Rails::Salt.new(klass, salt)

    error = assert_raises(StandardError) do
      salt_generator.generate!
    end

    assert_match(/salt is invalid/, error.message)
  end

  def test_raises_when_salt_is_blank
    klass = MyModel
    salt = ""
    salt_generator = EncodedId::Rails::Salt.new(klass, salt)

    error = assert_raises(StandardError) do
      salt_generator.generate!
    end

    assert_match(/salt is invalid/, error.message)
  end

  def test_raises_when_salt_is_too_short
    klass = MyModel
    salt = "abc" # Less than 4 characters
    salt_generator = EncodedId::Rails::Salt.new(klass, salt)

    error = assert_raises(StandardError) do
      salt_generator.generate!
    end

    assert_match(/salt is invalid/, error.message)
  end
end
