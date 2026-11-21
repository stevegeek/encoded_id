# frozen_string_literal: true

require "test_helper"
require "json"

class HexCompatibilityTest < Minitest::Test
  FIXTURES = JSON.parse(File.read(File.expand_path("../fixtures/hex_ids.json", __dir__))).freeze
  GROUP_SIZES = [1, 4, 8, 12].freeze

  def test_ids_issued_by_release_1_1_1_decode_as_they_did_then
    FIXTURES.fetch("release_1_1_1").each do |fixture|
      assert_equal fixture["decoded"], coder(fixture, :legacy).decode_hex(fixture["id"]), fixture.inspect
      assert_equal fixture["decoded"], coder(fixture, :tagged).decode_hex(fixture["id"], scheme: :legacy), fixture.inspect
    end
  end

  def test_legacy_encoding_matches_fixtures_and_round_trips
    FIXTURES.fetch("current").each do |fixture|
      coder = coder(fixture, :legacy)
      assert_equal fixture["id"], coder.encode_hex(fixture["input"]), fixture.inspect
      assert_equal without_dashes(fixture["input"]), coder.decode_hex(fixture["id"]), fixture.inspect
    end
  end

  def test_tagged_encoding_round_trips_the_fixture_inputs
    FIXTURES.values_at("release_1_1_1", "current").flatten.each do |fixture|
      coder = coder(fixture, :tagged)
      assert_equal without_dashes(fixture["input"]), coder.decode_hex(coder.encode_hex(fixture["input"])), fixture.inspect
    end
  end

  def test_fixtures_cover_both_encoders_and_every_group_size
    %w[release_1_1_1 current].each do |set|
      covered = FIXTURES.fetch(set).map { |fixture| [fixture["encoder"], fixture["group_size"]] }.uniq.sort
      assert_equal %w[hashid sqids].product(GROUP_SIZES), covered, set
    end
  end

  def test_legacy_decode_hex_is_canonical_for_random_integer_layouts
    random = Random.new(Minitest.seed)
    decoded_count = 0
    %w[sqids hashid].product(GROUP_SIZES).each do |encoder, group_size|
      coder = coder({"encoder" => encoder, "group_size" => group_size}, :legacy)
      separator = 16**group_size
      300.times do
        integers = Array.new(random.rand(1..5)) { random_group(random, separator, group_size) }
        id = coder.encode(integers)
        decoded = coder.decode_hex(id)
        next if decoded.empty?

        decoded_count += 1
        assert_includes canonical_ids(coder, decoded), id, "#{encoder} g=#{group_size} #{integers.inspect} -> #{decoded.inspect}"
      end
    end
    assert_operator decoded_count, :>, 500
  end

  def test_tagged_decode_hex_is_canonical_for_random_integer_layouts
    random = Random.new(Minitest.seed)
    decoded_count = 0
    %w[sqids hashid].each do |encoder|
      coder = coder({"encoder" => encoder, "group_size" => 4}, :tagged)
      1000.times do
        integers = Array.new(random.rand(1..5)) { random_tagged_chunk(random) }
        id = coder.encode(integers)
        decoded = coder.decode_hex(id)
        next if decoded.empty?

        decoded_count += 1
        assert_equal id, coder.encode_hex(decoded), "#{encoder} #{integers.inspect} -> #{decoded.inspect}"
      end
    end
    assert_operator decoded_count, :>, 100
  end

  private

  def coder(fixture, hex_encoding)
    options = {hex_digit_encoding_group_size: fixture["group_size"], hex_encoding: hex_encoding, max_length: nil}
    if fixture["encoder"] == "sqids"
      ::EncodedId::ReversibleId.sqids(**options)
    else
      ::EncodedId::ReversibleId.hashid(salt: FIXTURES.fetch("salt"), **options)
    end
  end

  # The second ID is the 1.1.1 encoding of an empty first string followed by the decoded strings
  def canonical_ids(coder, decoded)
    with_empty_first = coder.decode(coder.encode_hex(["", *decoded]))
    [coder.encode_hex(decoded), coder.encode(with_empty_first.drop(1))]
  end

  def without_dashes(input)
    Array(input).map { |hex| hex.delete("-") }
  end

  def random_tagged_chunk(random)
    tag = random.rand(4).zero? ? random.rand(4).to_s : %w[1 2].sample(random: random)
    length = random.rand(3).zero? ? random.rand(16) : [15, 14, 0].sample(random: random)
    (tag + Array.new(length) { random.rand(16).to_s(16) }.join).to_i(16)
  end

  def random_group(random, separator, group_size)
    case random.rand(4)
    when 0 then random.rand(separator)
    when 1 then random.rand(16)
    when 2 then separator
    else separator + 1 + random.rand(group_size + 2)
    end
  end
end
