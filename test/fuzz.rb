# frozen_string_literal: true

require "encoded_id"

require "fuzzbert"
require "json"

# Run this with:
# RUBYOPT='--yjit' bundle exec fuzzbert --pool-size 8 --limit 1000000 --console test/fuzz.rb

fuzz "JSON.parse" do
  deploy do |data|
    input = FuzzBert::Generators.random.call.chars.uniq
    alphabet = ::EncodedId::Alphabet.new(input)
    salt = FuzzBert::Generators.random.call
    split_with = FuzzBert::Generators.random(5).call
    split_at = rand(-500..10_000)
    length = rand(-500..10_000)
    hex_digit_encoding_group_size = rand(-5..70)
    max_length = rand(-500..10_000)
    reversible_id = ::EncodedId::ReversibleId.new(
      salt: salt,
      alphabet: alphabet,
      split_with: split_with,
      split_at: split_at,
      length: length,
      hex_digit_encoding_group_size: hex_digit_encoding_group_size,
      max_length: max_length
    )

    # # Test decode random fuzzed input
    reversible_id.decode(data)

    # Test encode/decode pair with inputs which will be converted using to_i
    ids = FuzzBert::Generators.random.call
    encoded = reversible_id.encode(ids.chars)
    decoded = reversible_id.decode(encoded)

    raise StandardError, "Decoded does not match input" unless decoded == ids.chars.map(&:to_i)

    # Test encode/decode with integer inputs
    encoded = reversible_id.encode(ids.codepoints)
    decoded = reversible_id.decode(encoded)

    raise StandardError, "Decoded does not match input" unless decoded == ids.codepoints
  rescue EncodedId::EncodedIdFormatError,
    EncodedId::InvalidInputError,
    EncodedId::InvalidConfigurationError,
    EncodedId::InvalidAlphabetError,
    EncodedId::EncodedIdLengthError
    # fine, these are expected errors
  rescue StandardError => e
    puts "\n\nFailure\n--------------\n"
    puts "Input: #{data}"
    puts "Alphabet: #{alphabet}"
    puts "Salt: #{salt}"
    puts "Split with: #{split_with}"
    puts "Split at: #{split_at}"
    puts "Length: #{length}"
    puts "Hex digit encoding group size: #{hex_digit_encoding_group_size}"
    puts "Max length: #{max_length}"
    puts "ReversibleId: #{reversible_id}"
    puts "ids: #{ids}"
    puts "encoded: #{encoded}"
    puts "decoded: #{decoded}"
    raise e
  end

  data "completely random" do
    FuzzBert::Generators.random
  end

  data "random hex string" do
    c = FuzzBert::Container.new
    c << FuzzBert::Generators.random_b64_fixlen(6)
    c << FuzzBert::Generators.fixed("--")
    c << FuzzBert::Generators.random_hex
    c.generator
  end

  data "my custom generator" do
    prng = Random.new
    lambda do
      buf = +"assd-"
      buf << prng.bytes(100)
      buf << "foo"
    end
  end
end
