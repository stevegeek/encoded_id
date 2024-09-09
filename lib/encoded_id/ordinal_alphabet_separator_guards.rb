# frozen_string_literal: true

module EncodedId
  class OrdinalAlphabetSeparatorGuards
    SEP_DIV = 3.5
    DEFAULT_SEPS = "cfhistuCFHISTU".chars.map(&:ord).freeze
    GUARD_DIV = 12.0
    SPACE_CHAR = " ".ord

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

    attr_reader :salt, :alphabet, :seps, :guards, :seps_tr_selector, :guards_tr_selector

    private

    def escape_characters_string_for_tr(chars)
      chars.join.gsub(/([-\\^])/) { "\\#{$1}" }
    end

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

          @seps += @alphabet[0, diff]
          @alphabet = @alphabet[diff..]
        else
          @seps = @seps[0, seps_length]
        end
      end

      consistent_shuffle!(@alphabet, @salt, nil, @salt.length)
    end

    def setup_guards
      gc = (@alphabet.length / GUARD_DIV).ceil

      if @alphabet.length < 3
        @guards = @seps[0, gc]
        @seps = @seps[gc..]
      else
        @guards = @alphabet[0, gc]
        @alphabet = @alphabet[gc..]
      end
    end

    def pick_characters(array, index)
      tail = array[index + 1..]
      head = array[0, index] + [SPACE_CHAR] # This space seems pointless but the original code does it, and its needed to maintain the same result in shuffling
      tail ? head + tail : head
    end

    def consistent_shuffle!(collection_to_shuffle, salt_part_1, salt_part_2, max_salt_length)
      HashIdConsistentShuffle.shuffle!(collection_to_shuffle, salt_part_1, salt_part_2, max_salt_length)
    end
  end
end
