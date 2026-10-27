# frozen_string_literal: true

require "test_helper"

class ImmutabilityTest < Minitest::Test
  SALT = "immutability-test-salt"
  HEX = "f1a2b3c4d5e6"

  def coders
    {
      hashid_default: -> { EncodedId::ReversibleId.hashid(salt: SALT) },
      hashid_blocklist_always: -> {
        EncodedId::ReversibleId.hashid(
          salt: SALT,
          min_length: 16,
          blocklist: EncodedId::Blocklist.new(%w[bad word]),
          blocklist_mode: :always
        )
      },
      sqids_default: -> { EncodedId::ReversibleId.sqids },
      sqids_blocklist_always: -> {
        EncodedId::ReversibleId.sqids(
          blocklist: EncodedId::Blocklist.new(EncodedId::Blocklist.sqids_blocklist.words),
          blocklist_mode: :always
        )
      },
      crockford_split: -> {
        EncodedId::ReversibleId.sqids(
          alphabet: EncodedId::Alphabet.modified_crockford,
          split_at: 4,
          split_with: "-"
        )
      }
    }
  end

  def record(coder)
    {
      array: coder.encode([1, 2, 3]),
      single: coder.encode(42),
      hex: coder.encode_hex(HEX)
    }
  end

  def invalid_decode_outcome(coder)
    coder.decode("!!!invalid!!!")
  rescue => error
    error.class
  end

  def test_coders_are_ractor_shareable_and_behave_the_same
    coders.each do |name, build|
      coder = build.call
      expected = record(coder)
      expected_invalid = invalid_decode_outcome(coder)

      Ractor.make_shareable(coder)

      assert Ractor.shareable?(coder), "#{name} is not shareable"
      assert_equal expected, record(coder), name.to_s
      assert_equal [1, 2, 3], coder.decode(expected[:array]), name.to_s
      assert_equal [42], coder.decode(expected[:single]), name.to_s
      assert_equal [HEX], coder.decode_hex(expected[:hex]), name.to_s
      assert_equal expected_invalid, invalid_decode_outcome(coder), name.to_s
    end
  end

  def test_shareable_coder_matches_fresh_coder
    coders.each do |name, build|
      shared = Ractor.make_shareable(build.call)
      assert_equal record(build.call), record(shared), name.to_s
    end
  end

  def test_alphabet_readers_are_frozen
    alphabet = EncodedId::Alphabet.modified_crockford

    assert_predicate alphabet.unique_characters, :frozen?
    assert alphabet.unique_characters.all?(&:frozen?)
    assert_predicate alphabet.characters, :frozen?
    assert_predicate alphabet.equivalences, :frozen?
    assert_raises(FrozenError) { alphabet.unique_characters << "z" }
    assert_raises(FrozenError) { alphabet.equivalences["q"] = "0" }
  end

  def test_alphabet_copies_are_mutable
    alphabet = EncodedId::Alphabet.modified_crockford

    refute_predicate alphabet.to_a, :frozen?
    refute_predicate alphabet.to_s, :frozen?
  end

  def test_blocklist_words_are_frozen
    blocklist = EncodedId::Blocklist.new(%w[bad word])

    assert_predicate blocklist.words, :frozen?
    assert_raises(FrozenError) { blocklist.words << "other" }
  end

  def test_hashid_readers_are_frozen
    coder = EncodedId::ReversibleId.hashid(salt: SALT)
    encoder = coder.encoder

    assert_predicate coder.config.salt, :frozen?
    assert_predicate encoder.salt, :frozen?
    assert_predicate encoder.salt_ordinals, :frozen?
    assert_predicate encoder.alphabet_ordinals, :frozen?
    assert_predicate encoder.separator_ordinals, :frozen?
    assert_predicate encoder.guard_ordinals, :frozen?
    assert_raises(FrozenError) { encoder.salt_ordinals << 1 }
  end

  def test_mutating_caller_salt_does_not_change_output
    salt = +"mutable-salt"
    coder = EncodedId::ReversibleId.hashid(salt: salt)
    expected = record(coder)

    refute_predicate salt, :frozen?
    salt << "-changed"

    assert_equal expected, record(coder)
  end

  def test_mutating_caller_equivalences_does_not_change_alphabet
    equivalences = {"o" => "0"}
    alphabet = EncodedId::Alphabet.new("0123456789abcdefghjkmnpqrstvwxyz", equivalences)
    coder = EncodedId::ReversibleId.sqids(alphabet: alphabet)
    value = (1..1000).find { |n| coder.encode(n).include?("0") }
    encoded = coder.encode(value)
    with_equivalent = encoded.tr("0", "o")

    refute_predicate equivalences, :frozen?
    equivalences["o"] = "1"
    equivalences["i"] = "1"

    assert_equal({"o" => "0"}, alphabet.equivalences)
    assert_equal encoded, coder.encode(value)
    assert_equal [value], coder.decode(with_equivalent)
  end
end
