# frozen_string_literal: true

require "test_helper"

class ThreadSafetyTest < Minitest::Test
  THREADS = 8
  ROUNDS = 300

  def test_a_shared_sqids_coder_gives_the_same_results_across_threads
    assert_consistent_across_threads(EncodedId::ReversibleId.sqids(blocklist: EncodedId::Blocklist.minimal))
  end

  def test_a_shared_hashid_coder_gives_the_same_results_across_threads
    assert_consistent_across_threads(EncodedId::ReversibleId.hashid(salt: "test-salt", blocklist: EncodedId::Blocklist.minimal))
  end

  def test_a_shared_rails_coder_gives_the_same_results_across_threads
    coder = EncodedId::Rails::Coder.new(
      salt: "test-salt", id_length: 8, max_length: 128, max_inputs_per_id: 32, hex_digit_encoding_group_size: 4,
      character_group_size: 4, alphabet: EncodedId::Alphabet.modified_crockford, separator: "-",
      encoder: :sqids, blocklist: nil, blocklist_mode: :length_threshold, blocklist_max_length: 32,
      downcase_on_decode: false
    )
    inputs = (1..ROUNDS).map { |i| [i * 7919, i] }
    expected = inputs.map { |ids| coder.encode(ids) }

    results = run_threads do
      inputs.each_with_index.map { |ids, i| coder.decode(expected[i]) == ids && coder.encode(ids) == expected[i] }
    end

    assert(results.flatten.all?)
  end

  private

  def assert_consistent_across_threads(coder)
    ints = (1..ROUNDS).map { |i| [i, i * 104_729, (i * 2_654_435_761) % 1_000_000_007] }
    hexes = (1..ROUNDS).map { |i| ["%x" % (i * 0x9e3779b97f4a7c15), "c0ffee%x" % i] }
    expected_ints = ints.map { |ids| coder.encode(ids) }
    expected_hexes = hexes.map { |hs| coder.encode_hex(hs) }

    results = run_threads do
      mismatches = []
      ints.each_with_index do |ids, i|
        mismatches << [:encode, ids] unless coder.encode(ids) == expected_ints[i]
        mismatches << [:decode, ids] unless coder.decode(expected_ints[i]) == ids
      end
      hexes.each_with_index do |hs, i|
        mismatches << [:encode_hex, hs] unless coder.encode_hex(hs) == expected_hexes[i]
        mismatches << [:decode_hex, hs] unless coder.decode_hex(expected_hexes[i]) == hs
      end
      mismatches
    end

    assert_empty results.flatten(1)
  end

  def run_threads(&block)
    start = Queue.new
    threads = Array.new(THREADS) do
      Thread.new do
        start.pop
        block.call
      end
    end
    THREADS.times { start << true }
    threads.map(&:value)
  end
end
