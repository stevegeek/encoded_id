# frozen_string_literal: true

# rbs_inline: enabled

module EncodedId
  # A blocklist of words that should not appear in encoded IDs.
  class Blocklist
    include Enumerable #[String]

    # @rbs @words: Set[String]
    # @rbs self.@empty: Blocklist
    # @rbs self.@minimal: Blocklist

    class << self
      # @rbs () -> Blocklist
      def sqids_blocklist
        new(::Sqids::DEFAULT_BLOCKLIST)
      end

      # @rbs () -> Blocklist
      def empty
        @empty ||= new([])
      end

      # @rbs () -> Blocklist
      def minimal
        @minimal ||= new([
          "ass", "cum", "fag", "fap", "fck", "fuk", "jiz", "pis", "poo", "sex",
          "tit", "xxx", "anal", "anus", "ball", "blow", "butt", "clit", "cock",
          "coon", "cunt", "dick", "dyke", "fart", "fuck", "jerk", "jizz", "jugs",
          "kike", "kunt", "muff", "nigg", "nigr", "piss", "poon", "poop", "porn",
          "pube", "pusy", "quim", "rape", "scat", "scum", "shit", "slut", "suck",
          "turd", "twat", "vag", "wank", "whor"
        ])
      end
    end

    attr_reader :words #: Set[String]

    # @rbs (?(Array[String] | Set[String]) words) -> void
    def initialize(words = [])
      @words = if words.is_a?(Array) || words.is_a?(Set)
        Set.new(words.map(&:to_s).map(&:downcase))
      else
        Set.new
      end
    end

    # @rbs () { (String) -> void } -> void
    def each(&block)
      @words.each(&block)
    end

    # @rbs (String word) -> bool
    def include?(word)
      @words.include?(word.to_s.downcase)
    end

    # @rbs (String string) -> (String | false)
    def blocks?(string)
      return false if empty?

      downcased_string = string.to_s.downcase
      @words.each do |word|
        return word if downcased_string.include?(word)
      end
      false
    end

    # @rbs () -> Integer
    def size
      @words.size
    end

    # @rbs () -> bool
    def empty?
      @words.empty?
    end

    # @rbs (Blocklist other_blocklist) -> Blocklist
    def merge(other_blocklist)
      self.class.new(to_a + other_blocklist.to_a)
    end

    # Filters the blocklist to only include words that can be formed from the given alphabet.
    # Only keeps words where ALL characters exist in the alphabet (case-insensitive).
    # Maintains minimum 3-character length requirement.
    #
    # @rbs (Alphabet | String alphabet) -> Blocklist
    def filter_for_alphabet(alphabet)
      alphabet_chars = Set.new(
        alphabet.is_a?(Alphabet) ? alphabet.unique_characters : alphabet.to_s.chars
      )

      self.class.new(
        @words.select { |word| word.length >= 3 && word.chars.to_set.subset?(alphabet_chars) }
      )
    end
  end
end
