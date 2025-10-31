# frozen_string_literal: true
# rbs_inline: enabled

module EncodedId
  module Encoders
    class HashIdOrdinalAlphabetSeparatorGuards
      SEP_DIV = 3.5
      DEFAULT_SEPS = "cfhistuCFHISTU".chars.map(&:ord).freeze
      GUARD_DIV = 12.0
      SPACE_CHAR = " ".ord

      # @rbs @alphabet: Array[Integer]
      # @rbs @salt: Array[Integer]
      # @rbs @seps: Array[Integer]
      # @rbs @guards: Array[Integer]
      # @rbs @seps_tr_selector: String
      # @rbs @guards_tr_selector: String

      # @rbs (Alphabet alphabet, String salt) -> void
      def initialize(alphabet, salt)
        @alphabet = alphabet.characters.chars.map(&:ord)
        @salt = salt.chars.map(&:ord)

        setup_seps
        setup_guards

        @seps_tr_selector = escape_characters_string_for_tr(@seps.map(&:chr))
        @guards_tr_selector = escape_characters_string_for_tr(@guards.map(&:chr))

        @alphabet.freeze
        @seps.freeze
        @guards.freeze
      end

      attr_reader :salt #: Array[Integer]
      attr_reader :alphabet #: Array[Integer]
      attr_reader :seps #: Array[Integer]
      attr_reader :guards #: Array[Integer]
      attr_reader :seps_tr_selector #: String
      attr_reader :guards_tr_selector #: String

      private

      # @rbs (Array[String] chars) -> String
      def escape_characters_string_for_tr(chars)
        chars.join.gsub(/([-\\^])/) { "\\#{$1}" }
      end

      # @rbs () -> void
      def setup_seps
        @seps = DEFAULT_SEPS.dup

        @seps.length.times do |i|
          # Seps should only contain characters present in alphabet,
          # and alphabet should not contains seps
          if (j = @alphabet.index(@seps[i]))
            @alphabet = pick_characters(@alphabet, j)
          else
            @seps = pick_characters(@seps, i)
          end
        end

        @alphabet.delete(SPACE_CHAR)
        @seps.delete(SPACE_CHAR)

        consistent_shuffle!(@seps, @salt, nil, @salt.length)

        if @seps.length == 0 || (@alphabet.length / @seps.length.to_f) > SEP_DIV
          seps_length = (@alphabet.length / SEP_DIV).ceil
          seps_length = 2 if seps_length == 1

          if seps_length > @seps.length
            diff = seps_length - @seps.length

            additonal_seps = @alphabet[0, diff] #: Array[Integer]
            @seps += additonal_seps
            @alphabet = @alphabet[diff..] #: Array[Integer]
          else
            @seps = @seps[0, seps_length] #: Array[Integer]
          end
        end

        consistent_shuffle!(@alphabet, @salt, nil, @salt.length)
      end

      # @rbs () -> void
      def setup_guards
        gc = (@alphabet.length / GUARD_DIV).ceil

        if @alphabet.length < 3
          @guards = @seps[0, gc] #: Array[Integer]
          @seps = @seps[gc..] #: Array[Integer]
        else
          @guards = @alphabet[0, gc] #: Array[Integer]
          @alphabet = @alphabet[gc..] #: Array[Integer]
        end
      end

      # @rbs (Array[Integer] array, Integer index) -> Array[Integer]
      def pick_characters(array, index)
        tail = array[index + 1..]
        head = array[0, index] + [SPACE_CHAR] # This space seems pointless but the original code does it, and its needed to maintain the same result in shuffling
        tail ? head + tail : head
      end

      # @rbs (Array[Integer] collection_to_shuffle, Array[Integer] salt_part_1, Array[Integer]? salt_part_2, Integer max_salt_length) -> Array[Integer]
      def consistent_shuffle!(collection_to_shuffle, salt_part_1, salt_part_2, max_salt_length)
        HashIdConsistentShuffle.shuffle!(collection_to_shuffle, salt_part_1, salt_part_2, max_salt_length)
      end
    end
  end
end
