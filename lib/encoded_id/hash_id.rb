# frozen_string_literal: true

# This implementation based on https://github.com/peterhellberg/hashids.rb
#
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
#
# This version also MIT licensed (Stephen Ierodiaconou): see LICENSE.txt file
module EncodedId
  class HashId
    def initialize(salt, min_hash_length = 0, alphabet = Alphabet.alphanum)
      unless min_hash_length.is_a?(Integer) && min_hash_length >= 0
        raise ArgumentError, "The min length must be a Integer and greater than or equal to 0"
      end
      @min_hash_length = min_hash_length

      # TODO: move this class creation out of the constructor?
      @separators_and_guards = OrdinalAlphabetSeparatorGuards.new(alphabet, salt)
      @alphabet_ordinals = @separators_and_guards.alphabet
      @separator_ordinals = @separators_and_guards.seps
      @guard_ordinals = @separators_and_guards.guards
      @salt_ordinals = @separators_and_guards.salt

      @escaped_separator_selector = @separators_and_guards.seps_tr_selector
      @escaped_guards_selector = @separators_and_guards.guards_tr_selector
    end

    attr_reader :alphabet_ordinals, :separator_ordinals, :guard_ordinals, :salt_ordinals

    def encode(*numbers)
      numbers.flatten! if numbers.length == 1

      numbers.map! { |n| Integer(n) } # raises if conversion fails

      return "" if numbers.empty? || numbers.any? { |n| n < 0 }

      internal_encode(numbers)
    end

    def encode_hex(str)
      return "" unless hex_string?(str)

      numbers = str.scan(/[\w\W]{1,12}/).map do |num|
        "1#{num}".to_i(16)
      end

      encode(numbers)
    end

    def decode(hash)
      return [] if hash.nil? || hash.empty?

      internal_decode(hash)
    end

    def decode_hex(hash)
      numbers = decode(hash)

      ret = numbers.map do |n|
        n.to_s(16)[1..]
      end

      ret.join.upcase
    end

    protected

    def internal_encode(numbers)
      current_alphabet = @alphabet_ordinals
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

      # ret is the final string form of the hash, we create it here
      ret = lottery.chr # Working with ordinals
      seasoning = [lottery].concat(@salt_ordinals)

      i = 0
      while i < length
        num = numbers[i]
        current_alphabet = consistent_shuffle(current_alphabet, seasoning, current_alphabet, alphabet_length)
        hash = hash_one_number(num, current_alphabet, alphabet_length)

        # Add the hash to the final string
        ret << hash
        last_char_ord = hash.ord

        if (i + 1) < length
          num %= (last_char_ord + i)
          ret << separator_ordinals[num % separator_ordinals.length].chr # Working with ordinals
        end

        i += 1
      end

      if ret.length < @min_hash_length
        ret.prepend(guard_ordinals[(hash_int + ret[0].ord) % guard_ordinals.length].chr) # Working with ordinals

        if ret.length < @min_hash_length
          ret << guard_ordinals[(hash_int + ret[2].ord) % guard_ordinals.length].chr # Working with ordinals
        end
      end

      half_length = current_alphabet.length.div(2)

      while ret.length < @min_hash_length
        current_alphabet = consistent_shuffle(current_alphabet, current_alphabet, nil, current_alphabet.length)
        ret.prepend(*current_alphabet[half_length..].map(&:chr)) # Working with ordinals
        ret.concat(*current_alphabet[0, half_length].map(&:chr)) # Working with ordinals

        excess = ret.length - @min_hash_length
        ret = ret[excess / 2, @min_hash_length] if excess > 0
      end

      ret
    end

    def internal_decode(hash)
      ret = []
      current_alphabet = @alphabet_ordinals
      salt_ordinals= @salt_ordinals

      breakdown = hash.tr(@escaped_guards_selector, " ")
      array = breakdown.split(" ")

      i = [3, 2].include?(array.length) ? 1 : 0

      if (breakdown = array[i])
        lottery, breakdown = breakdown[0], breakdown[1..]
        breakdown.tr!(@escaped_separator_selector, " ")
        array = breakdown.split(" ")

        seasoning = [lottery.ord].concat(salt_ordinals) # Working with ordinals

        array.length.times do |time|
          sub_hash = array[time]
          current_alphabet = consistent_shuffle(current_alphabet, seasoning, current_alphabet, current_alphabet.length)

          ret.push unhash(sub_hash, current_alphabet)
        end

        if encode(ret) != hash
          ret = []
        end
      end

      ret
    end

    def hash_one_number(num, alphabet, alphabet_length)
      res = +""

      while true
        res.prepend alphabet[num % alphabet_length].chr # Working with ordinals
        num /= alphabet_length
        break unless num > 0
      end

      res
    end

    def unhash(input, alphabet)
      num = 0

      input.length.times do |i|
        pos = alphabet.index(input[i].ord) # Working with ordinals

        raise InvalidInputError, "unable to unhash" unless pos

        num += pos * alphabet.length**(input.length - i - 1)
      end

      num
    end

    private

    def hex_string?(string)
      string.to_s.match(/\A[0-9a-fA-F]+\Z/)
    end

    def consistent_shuffle(collection_to_shuffle, salt_part_1, salt_part_2, max_salt_length)
      HashIdConsistentShuffle.call(collection_to_shuffle, salt_part_1, salt_part_2, max_salt_length)
    end
  end
end
