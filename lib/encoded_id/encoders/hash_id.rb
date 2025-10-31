# frozen_string_literal: true

# This implementation based on https://github.com/peterhellberg/hashids.rb
# --------------------------------------------------------------------------
# Original Hashids implementation is MIT licensed:
#
# Copyright (c) 2013-2017 Peter Hellberg
#
# MIT License
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
# --------------------------------------------------------------------------
#
# This version also MIT licensed (Stephen Ierodiaconou 2023-2025):
# see LICENSE.txt file
# rbs_inline: enabled

module EncodedId
  module Encoders
    class HashId < Base
      # @rbs @separators_and_guards: HashIdOrdinalAlphabetSeparatorGuards
      # @rbs @alphabet_ordinals: Array[Integer]
      # @rbs @separator_ordinals: Array[Integer]
      # @rbs @guard_ordinals: Array[Integer]
      # @rbs @salt_ordinals: Array[Integer]
      # @rbs @escaped_separator_selector: String
      # @rbs @escaped_guards_selector: String

      # @rbs (String salt, ?Integer min_hash_length, ?Alphabet alphabet, ?Blocklist? blocklist) -> void
      def initialize(salt, min_hash_length = 0, alphabet = Alphabet.alphanum, blocklist = nil)
        super

        unless min_hash_length.is_a?(Integer) && min_hash_length >= 0
          raise ArgumentError, "The min length must be a Integer and greater than or equal to 0"
        end
        @min_hash_length = min_hash_length

        # Create the helper objects for hashids encoding
        @separators_and_guards = HashIdOrdinalAlphabetSeparatorGuards.new(alphabet, salt)
        @alphabet_ordinals = @separators_and_guards.alphabet
        @separator_ordinals = @separators_and_guards.seps
        @guard_ordinals = @separators_and_guards.guards
        @salt_ordinals = @separators_and_guards.salt

        @escaped_separator_selector = @separators_and_guards.seps_tr_selector
        @escaped_guards_selector = @separators_and_guards.guards_tr_selector
      end

      attr_reader :alphabet_ordinals #: Array[Integer]
      attr_reader :separator_ordinals #: Array[Integer]
      attr_reader :guard_ordinals #: Array[Integer]
      attr_reader :salt_ordinals #: Array[Integer]

      # @rbs (Array[Integer] numbers) -> String
      def encode(numbers)
        numbers.all? { |n| Integer(n) } # raises if conversion fails

        return "" if numbers.empty? || numbers.any? { |n| n < 0 }

        encoded = internal_encode(numbers)
        if blocklist && !blocklist.empty?
          blocked_word = contains_blocklisted_word?(encoded)
          if blocked_word
            raise EncodedId::InvalidInputError, "Generated ID contains blocklisted word: '#{blocked_word}'"
          end
        end

        encoded
      end

      # @rbs (String hash) -> Array[Integer]
      def decode(hash)
        return [] if hash.nil? || hash.empty?

        internal_decode(hash)
      end

      # @rbs (String hash) -> String
      def decode_hex(hash)
        numbers = decode(hash)

        ret = numbers.map do |n|
          n.to_s(16)[1..]
        end

        ret.join.upcase
      end

      private

      # @rbs (Array[Integer] numbers) -> String
      def internal_encode(numbers)
        current_alphabet = @alphabet_ordinals.dup
        separator_ordinals = @separator_ordinals
        guard_ordinals = @guard_ordinals

        alphabet_length = current_alphabet.length
        length = numbers.length

        hash_int = 0
        # We dont use the iterator#sum to avoid the extra array allocation
        i = 0
        while i < length
          hash_int += numbers[i] % (i + 100)
          i += 1
        end

        lottery = current_alphabet[hash_int % alphabet_length]

        # This is the final string form of the hash, as an array of ordinals
        # @type var hashid_code: Array[Integer]
        hashid_code = []
        hashid_code << lottery
        seasoning = [lottery].concat(@salt_ordinals)

        i = 0
        while i < length
          num = numbers[i]
          consistent_shuffle!(current_alphabet, seasoning, current_alphabet.dup, alphabet_length)
          last_char_ord = hash_one_number(hashid_code, num, current_alphabet, alphabet_length)

          if (i + 1) < length
            num %= (last_char_ord + i)
            hashid_code << separator_ordinals[num % separator_ordinals.length]
          end

          i += 1
        end

        if hashid_code.length < @min_hash_length
          hashid_code.prepend(guard_ordinals[(hash_int + hashid_code[0]) % guard_ordinals.length])

          if hashid_code.length < @min_hash_length
            hashid_code << guard_ordinals[(hash_int + hashid_code[2]) % guard_ordinals.length]
          end
        end

        half_length = current_alphabet.length.div(2)

        while hashid_code.length < @min_hash_length
          consistent_shuffle!(current_alphabet, current_alphabet.dup, nil, current_alphabet.length)
          hashid_code.prepend(*current_alphabet[half_length..])
          hashid_code.concat(current_alphabet[0, half_length])

          excess = hashid_code.length - @min_hash_length
          hashid_code = hashid_code[excess / 2, @min_hash_length] if excess > 0
        end

        # Convert the array of ordinals to a string
        hashid_code.pack("U*")
      end

      # @rbs (String hash) -> Array[Integer]
      def internal_decode(hash)
        # @type var ret: Array[Integer]
        ret = []
        current_alphabet = @alphabet_ordinals.dup
        salt_ordinals = @salt_ordinals

        breakdown = hash.tr(@escaped_guards_selector, " ")
        array = breakdown.split(" ")

        i = [3, 2].include?(array.length) ? 1 : 0

        if (breakdown = array[i])
          lottery, breakdown = breakdown[0], breakdown[1..]
          breakdown.tr!(@escaped_separator_selector, " ")
          sub_hashes = breakdown.split(" ")

          seasoning = [lottery.ord].concat(salt_ordinals)

          len = sub_hashes.length
          time = 0
          while time < len
            sub_hash = sub_hashes[time]
            consistent_shuffle!(current_alphabet, seasoning, current_alphabet.dup, current_alphabet.length)

            ret.push unhash(sub_hash, current_alphabet)
            time += 1
          end

          # Check if the result is consistent with the hash, this is important for safety since otherwise
          # a random string could feasibly decode to a set of numbers
          if encode(ret) != hash
            # @type var ret: Array[Integer]
            ret = []
          end
        end

        ret
      end

      # @rbs (Array[Integer] hash_code, Integer num, Array[Integer] alphabet, Integer alphabet_length) -> Integer
      def hash_one_number(hash_code, num, alphabet, alphabet_length)
        char = 0 #: Integer
        insert_at = 0
        while true # standard:disable Style/InfiniteLoop
          char = alphabet[num % alphabet_length] || 0
          insert_at -= 1
          hash_code.insert(insert_at, char)
          num /= alphabet_length
          break unless num > 0
        end

        char
      end

      # @rbs (String input, Array[Integer] alphabet) -> Integer
      def unhash(input, alphabet)
        num = 0 #: Integer
        input_length = input.length
        alphabet_length = alphabet.length
        i = 0
        while i < input_length
          first_char = input[i] #: String
          pos = alphabet.index(first_char.ord)
          raise InvalidInputError, "unable to unhash" unless pos

          exponent = input_length - i - 1
          multiplier = alphabet_length**exponent #: Integer
          num += pos * multiplier
          i += 1
        end

        num
      end

      # @rbs (Array[Integer] collection_to_shuffle, Array[Integer] salt_part_1, Array[Integer]? salt_part_2, Integer max_salt_length) -> Array[Integer]
      def consistent_shuffle!(collection_to_shuffle, salt_part_1, salt_part_2, max_salt_length)
        HashIdConsistentShuffle.shuffle!(collection_to_shuffle, salt_part_1, salt_part_2, max_salt_length)
      end

      # @rbs (String encoded_string) -> (String | false)
      def contains_blocklisted_word?(encoded_string)
        return false unless @blocklist && !@blocklist.empty?

        blocked_word = @blocklist.blocks?(encoded_string)
        return blocked_word if blocked_word

        false
      end
    end
  end
end
