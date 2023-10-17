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
    ::EncodedId::ReversibleId.new(
      salt: salt,
      alphabet: alphabet,
      split_with: FuzzBert::Generators.random(5).call,
      split_at: rand(-500..10_000),
      length: rand(-500..10_000),
      hex_digit_encoding_group_size: rand(-5..70),
      max_length: rand(-500..10_000)
    ).decode(data)

    # Test encode/decode pair
    # TODO:
    #
  rescue EncodedId::EncodedIdFormatError,
    EncodedId::InvalidInputError,
    EncodedId::InvalidConfigurationError,
    EncodedId::InvalidAlphabetError
    # fine, these are expected errors
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
