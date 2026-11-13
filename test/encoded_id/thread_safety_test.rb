# frozen_string_literal: true

require "test_helper"

class ThreadSafetyTest < Minitest::Test
  THREAD_COUNT = 8
  SALT = "thread-safety-salt"
  BLOCKLIST_WORDS = %w[bad cab dab fab gag jab nag tab].freeze
  HEX_INPUTS = [
    "0",
    "f",
    "deadbeef",
    "0123456789abcdef",
    "9a566b8b-8618-42ab-8db7-a5a0276401fd",
    ["ab", "cd", "ef"]
  ].freeze

  def test_shared_hashid_coder_gives_single_threaded_results
    assert_shared_coder_consistent(build_hashid, max_value: 2**64 - 1)
  end

  def test_shared_sqids_coder_with_defaults_gives_single_threaded_results
    assert_shared_coder_consistent(::EncodedId::ReversibleId.sqids, max_value: ::MySqids.max_value)
  end

  def test_shared_sqids_coder_with_min_length_and_blocklist_gives_single_threaded_results
    assert_shared_coder_consistent(build_sqids, max_value: ::MySqids.max_value)
  end

  def test_coders_built_concurrently_encode_identically
    inputs = build_inputs(::MySqids.max_value).first(50)
    builders = {
      hashid: -> { build_hashid },
      sqids: -> { build_sqids },
      sqids_defaults: -> { ::EncodedId::ReversibleId.sqids }
    }

    builders.each do |name, builder|
      expected = encode_all(builder.call, inputs)
      results = run_in_threads { |_index| encode_all(builder.call, inputs) }

      results.each do |result|
        assert_equal expected, result, "#{name} coder built in a thread encoded differently"
      end
    end
  end

  private

  def build_hashid
    ::EncodedId::ReversibleId.hashid(
      salt: SALT,
      min_length: 12,
      blocklist: ::EncodedId::Blocklist.new(BLOCKLIST_WORDS),
      blocklist_mode: :always
    )
  end

  def build_sqids
    ::EncodedId::ReversibleId.sqids(
      min_length: 12,
      blocklist: ::EncodedId::Blocklist.new(BLOCKLIST_WORDS),
      blocklist_mode: :always
    )
  end

  def build_inputs(max_value)
    singles = (0...100).to_a
    pairs = (0...80).map { |i| [i, i * 7 + 1] }
    triples = (0...80).map { |i| [i * 13, i * 31 + 5, i * 101 + 7] }
    large = [
      max_value,
      max_value - 1,
      max_value - 12_345,
      max_value / 2,
      2**32,
      2**53 + 1,
      [max_value, 0],
      [0, max_value],
      [max_value, max_value],
      [max_value, 1, max_value],
      [max_value, max_value, max_value],
      [2**40, 2**48, 2**56]
    ]
    singles + pairs + triples + large
  end

  def encode_all(coder, inputs)
    inputs.map do |input|
      coder.encode(input)
    rescue ::EncodedId::BlocklistError
      nil
    end
  end

  def expected_results(coder, inputs)
    inputs.each_with_object({}) do |input, expected|
      encoded = coder.encode(input)
      expected[input] = [encoded, coder.decode(encoded)]
    rescue ::EncodedId::BlocklistError
      next
    end
  end

  def expected_hex_results(coder)
    HEX_INPUTS.to_h do |hex|
      encoded = coder.encode_hex(hex)
      [hex, [encoded, coder.decode_hex(encoded)]]
    end
  end

  def assert_shared_coder_consistent(coder, max_value:)
    expected = expected_results(coder, build_inputs(max_value))
    expected_hex = expected_hex_results(coder)

    assert_operator expected.size, :>, 250
    expected.each do |input, (_encoded, decoded)|
      assert_equal Array(input), decoded
    end

    mismatches = Queue.new
    run_in_threads do |index|
      random = Random.new(index)
      expected.keys.shuffle(random: random).each do |input|
        encoded, decoded = expected[input]
        actual_encoded = coder.encode(input)
        actual_decoded = coder.decode(encoded)
        mismatches << [:encode, input, encoded, actual_encoded] unless actual_encoded == encoded
        mismatches << [:decode, encoded, decoded, actual_decoded] unless actual_decoded == decoded
      end

      expected_hex.keys.shuffle(random: random).each do |hex|
        encoded, decoded = expected_hex[hex]
        actual_encoded = coder.encode_hex(hex)
        actual_decoded = coder.decode_hex(encoded)
        mismatches << [:encode_hex, hex, encoded, actual_encoded] unless actual_encoded == encoded
        mismatches << [:decode_hex, encoded, decoded, actual_decoded] unless actual_decoded == decoded
      end
    end

    assert_empty Array.new(mismatches.size) { mismatches.pop }
  end

  def run_in_threads
    start = Queue.new
    threads = Array.new(THREAD_COUNT) do |index|
      Thread.new do
        Thread.current.report_on_exception = false
        start.pop
        yield index
      end
    end
    THREAD_COUNT.times { start << true }
    threads.map(&:value)
  end
end
