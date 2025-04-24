# frozen_string_literal: true

module EncodedId
  class Blocklist
    include Enumerable
    class << self
      def sqids_blocklist
        if defined?(::Sqids::DEFAULT_BLOCKLIST)
          new(::Sqids::DEFAULT_BLOCKLIST)
        else
          empty
        end
      end

      def empty
        @empty ||= new([])
      end

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

    attr_reader :words

    def initialize(words = [])
      @words = if words.is_a?(Array) || words.is_a?(Set)
        Set.new(words.map(&:to_s).map(&:downcase))
      else
        Set.new
      end
    end

    def each(&block)
      @words.each(&block)
    end

    def include?(word)
      @words.include?(word.to_s.downcase)
    end

    def blocks?(string)
      return false if empty?

      downcased_string = string.to_s.downcase
      @words.each do |word|
        return word if downcased_string.include?(word)
      end
      false
    end

    def size
      @words.size
    end

    def empty?
      @words.empty?
    end

    def merge(other_blocklist)
      self.class.new(to_a + other_blocklist.to_a)
    end
  end
end
