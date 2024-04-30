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
    MIN_ALPHABET_LENGTH = 16
    SEP_DIV = 3.5
    GUARD_DIV = 12.0

    DEFAULT_SEPS = "cfhistuCFHISTU"

    DEFAULT_ALPHABET = "abcdefghijklmnopqrstuvwxyz" \
      "ABCDEFGHIJKLMNOPQRSTUVWXYZ" \
      "1234567890"

    attr_reader :salt, :min_hash_length, :seps, :guards

    def alphabet
      @alphabet.join
    end

    def initialize(salt = "", min_hash_length = 0, alphabet = DEFAULT_ALPHABET)
      @salt = salt
      @min_hash_length = min_hash_length
      @alphabet = alphabet.freeze

      validate_attributes

      @salt_chars = salt.chars
      setup_alphabet
    end

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

      internal_decode(hash, @alphabet)
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
      current_alphabet = @alphabet
      alphabet_length = current_alphabet.length
      length = numbers.length

      hash_int = 0
      # We dont use the iterator#sum to avoid the extra array allocation
      numbers.each_with_index do |n, i|
        hash_int += n % (i + 100)
      end
      lottery = current_alphabet[hash_int % alphabet_length]

      ret = lottery.dup
      seasoning = [lottery].concat(@salt_chars)

      numbers.each_with_index do |num, i|
        current_alphabet = consistent_shuffle(current_alphabet, seasoning, current_alphabet, alphabet_length)
        last = hash_one_number(num, current_alphabet, alphabet_length)

        ret << last

        if (i + 1) < length
          num %= (last.ord + i)
          ret << seps[num % seps.length]
        end
      end

      if ret.length < min_hash_length
        ret.prepend(guards[(hash_int + ret[0].ord) % guards.length])

        if ret.length < min_hash_length
          ret << guards[(hash_int + ret[2].ord) % guards.length]
        end
      end

      half_length = current_alphabet.length.div(2)

      while ret.length < min_hash_length
        current_alphabet = consistent_shuffle(current_alphabet, current_alphabet, nil, current_alphabet.length)
        ret.prepend(*current_alphabet[half_length..])
        ret.concat(*current_alphabet[0, half_length])

        excess = ret.length - min_hash_length
        ret = ret[excess / 2, min_hash_length] if excess > 0
      end

      ret
    end

    def internal_decode(hash, alphabet)
      ret = []

      breakdown = hash.tr(@escaped_guards_selector, " ")
      array = breakdown.split(" ")

      i = [3, 2].include?(array.length) ? 1 : 0

      if (breakdown = array[i])
        lottery = breakdown[0]
        breakdown = breakdown[1..].tr(@escaped_seps_selector, " ")
        array = breakdown.split(" ")

        seasoning = [lottery].concat(@salt_chars)

        array.length.times do |time|
          sub_hash = array[time]
          alphabet = consistent_shuffle(alphabet, seasoning, alphabet, alphabet.length)

          ret.push unhash(sub_hash, alphabet)
        end

        if encode(ret) != hash
          ret = []
        end
      end

      ret
    end

    def consistent_shuffle(collection_to_shuffle, salt_part_1, salt_part_2, max_salt_length)
      salt_part_1_length = salt_part_1.length

      return collection_to_shuffle if collection_to_shuffle.empty? || max_salt_length == 0 || salt_part_1.nil? || salt_part_1_length == 0

      chars = collection_to_shuffle.dup

      idx = ord_total = 0

      i = collection_to_shuffle.length - 1
      while i >= 1
        raise ArgumentError, "Salt is too short in shuffle" if idx >= salt_part_1_length && salt_part_2.nil?
        ord_total += n = ((idx >= salt_part_1_length) ? salt_part_2[idx - salt_part_1_length] : salt_part_1[idx]).ord
        j = (n + idx + ord_total) % i

        tmp = chars[i]
        chars[i] = chars[j]
        chars[j] = tmp

        idx = (idx + 1) % max_salt_length
        i -= 1
      end

      chars
    end

    def hash_one_number(num, alphabet, alphabet_length)
      res = +""

      loop do
        res.prepend alphabet[num % alphabet_length]
        num /= alphabet_length
        break unless num > 0
      end

      res
    end

    def unhash(input, alphabet)
      num = 0

      input.length.times do |i|
        pos = alphabet.index(input[i])

        raise InputError, "unable to unhash" unless pos

        num += pos * alphabet.length**(input.length - i - 1)
      end

      num
    end

    private

    def setup_alphabet
      @alphabet = uniq_characters(@alphabet)

      validate_alphabet

      setup_seps
      setup_guards

      @seps = @seps.chars
      @guards = @guards.is_a?(Array) ? @guards : @guards.chars

      @escaped_guards_selector = @guards.join.gsub(/([-\\^])/) { "\\#{$1}" }
      @escaped_seps_selector = @seps.join.gsub(/([-\\^])/) { "\\#{$1}" }
    end

    def setup_seps
      @seps = DEFAULT_SEPS.dup

      seps.length.times do |i|
        # Seps should only contain characters present in alphabet,
        # and alphabet should not contains seps
        if (j = @alphabet.index(seps[i]))
          @alphabet = pick_characters(@alphabet, j)
        else
          @seps = pick_characters(seps, i)
        end
      end

      @alphabet.delete!(" ")
      @seps.delete!(" ")

      chars = @seps.chars
      @seps = consistent_shuffle(chars, @salt_chars, nil, @salt_chars.length).join

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

      chars = @alphabet.chars
      @alphabet = consistent_shuffle(chars, @salt_chars, nil, @salt_chars.length)
    end

    def setup_guards
      gc = (@alphabet.length / GUARD_DIV).ceil

      if @alphabet.length < 3
        @guards = seps[0, gc]
        @seps = seps[gc..]
      else
        @guards = @alphabet[0, gc]
        @alphabet = @alphabet[gc..]
      end
    end

    SaltError = Class.new(ArgumentError)
    MinLengthError = Class.new(ArgumentError)
    AlphabetError = Class.new(ArgumentError)
    InputError = Class.new(ArgumentError)

    def validate_attributes
      unless salt.is_a?(String)
        raise SaltError, "The salt must be a String"
      end

      unless min_hash_length.is_a?(Integer)
        raise MinLengthError, "The min length must be a Integer"
      end

      unless min_hash_length >= 0
        raise MinLengthError, "The min length must be 0 or more"
      end

      unless @alphabet.is_a?(String)
        raise AlphabetError, "The alphabet must be a String"
      end

      if @alphabet.include?(" ")
        raise AlphabetError, "The alphabet can’t include spaces"
      end
    end

    def validate_alphabet
      unless @alphabet.length >= MIN_ALPHABET_LENGTH
        raise AlphabetError, "Alphabet must contain at least #{MIN_ALPHABET_LENGTH} unique characters."
      end
    end

    def hex_string?(string)
      string.to_s.match(/\A[0-9a-fA-F]+\Z/)
    end

    def pick_characters(array, index)
      array[0, index] + " " + array[index + 1..]
    end

    def uniq_characters(string)
      string.chars.uniq.join("")
    end
  end
end
