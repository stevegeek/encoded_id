# frozen_string_literal: true

require "test_helper"
require "base64"

class Base64Encoder
  attr_reader :salt, :alphabet, :blocklist, :min_hash_length

  def initialize(salt, min_hash_length = 0, alphabet = nil, blocklist = nil)
    @salt = salt
    @min_hash_length = min_hash_length
    @alphabet = alphabet || EncodedId::Alphabet.alphanum
    @blocklist = blocklist
  end

  def encode(numbers)
    data = numbers.map(&:to_s).join(",")
    Base64.urlsafe_encode64(data, padding: false)
  end

  def decode(hash)
    # Base64 decoding is case-sensitive, so we need to retain the case
    # We need to handle the case where 'hash' might be downcased or symbols might be removed by the parent

    # Add padding if needed for Base64 decoding
    padded_hash = hash
    mod = hash.length % 4
    if mod > 0
      padded_hash += "=" * (4 - mod)
    end

    begin
      data = Base64.urlsafe_decode64(padded_hash)
      data.split(",").map(&:to_i)
    rescue => e
      raise EncodedId::InvalidInputError, "unable to decode Base64 data: #{e.message}"
    end
  end
end

# Custom configuration class for Base64 encoder
class Base64Configuration < EncodedId::Encoders::BaseConfiguration
  attr_reader :salt

  def initialize(salt:, **options)
    @salt = salt
    super(**options)
  end

  def encoder_type
    :base64
  end

  # Create the Base64 encoder instance
  def create_encoder
    Base64Encoder.new(salt, min_length, alphabet, blocklist)
  end
end

class CustomEncoderTest < Minitest::Test
  def setup
    @salt = "this is my salt"

    # Create custom configuration
    @config = Base64Configuration.new(
      salt: @salt,
      split_at: nil,
      split_with: "-"
    )

    # Create ReversibleId with custom configuration
    @reversible_id = EncodedId::ReversibleId.new(@config)

    @custom_encoder = Base64Encoder.new(@salt)

    # Test the encoder works directly first
    assert_equal "MTIzNDU", @custom_encoder.encode([12345])
    assert_equal [12345], @custom_encoder.decode("MTIzNDU")
  end

  def test_custom_base64_encoder
    input = 12345
    encoded = @reversible_id.encode(input)
    decoded = @reversible_id.decode(encoded, downcase: false)
    assert_equal input, decoded.first

    input_array = [1, 2, 3, 4, 5]
    encoded = @reversible_id.encode(input_array)
    assert_equal input_array, @reversible_id.decode(encoded, downcase: false)

    encoded_output = @reversible_id.encode([1, 2, 3, 4, 5])
    expected_base64 = Base64.urlsafe_encode64("1,2,3,4,5", padding: false)
    assert_equal expected_base64, encoded_output
  end

  def test_custom_base64_encoder_handles_large_numbers
    large_numbers = [9876543210, 1234567890]
    encoded = @reversible_id.encode(large_numbers)
    decoded = @reversible_id.decode(encoded, downcase: false)
    assert_equal large_numbers, decoded
  end

  def test_error_handling_with_invalid_data
    assert_raises(EncodedId::EncodedIdFormatError) do
      @reversible_id.decode("!!invalid!!")
    end
  end
end
