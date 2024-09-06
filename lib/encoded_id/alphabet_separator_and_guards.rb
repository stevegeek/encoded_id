# frozen_string_literal: true

module EncodedId
  class AlphabetSeparatorAndGuards
    SEP_DIV = 3.5
    DEFAULT_SEPS = "cfhistuCFHISTU"
    GUARD_DIV = 12.0

    def self.selector_regex(chars)
      chars.join.gsub(/([-\\^])/) { "\\#{$1}" }
    end

    def initialize(alphabet, salt)
      @alphabet = alphabet.characters
      @salt_chars = salt.chars

      setup_seps
      setup_guards

      @alphabet.freeze
      @seps.freeze
      @guards.freeze
    end

    def alphabet_chars
      @alphabet
    end

    def separator_chars
      @seps.chars.freeze
    end

    def guard_chars
      @guards
    end

    private

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

      @alphabet.delete!(" ")
      @seps.delete!(" ")

      @seps = consistent_shuffle(@seps.chars, @salt_chars, nil, @salt_chars.length).join

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

      @alphabet = consistent_shuffle(@alphabet.chars, @salt_chars, nil, @salt_chars.length)
    end

    def setup_guards
      gc = (@alphabet.length / GUARD_DIV).ceil

      if @alphabet.length < 3
        @guards = @seps[0, gc].chars
        @seps = @seps[gc..]
      else
        @guards = @alphabet[0, gc]
        @alphabet = @alphabet[gc..]
      end
    end

    def pick_characters(array, index)
      array[0, index] + " " + array[index + 1..]
    end

    def consistent_shuffle(collection_to_shuffle, salt_part_1, salt_part_2, max_salt_length)
      HashIdConsistentShuffle.call_with_string(collection_to_shuffle, salt_part_1, salt_part_2, max_salt_length)
    end
  end
end
