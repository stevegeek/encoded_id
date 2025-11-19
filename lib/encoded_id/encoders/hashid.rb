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

# == HashID Algorithm Overview
#
# Hashids is a small library that generates short, unique, non-sequential IDs from numbers.
# The algorithm has several key properties:
#
# 1. **Deterministic**: Same input numbers always produce the same hash
# 2. **Reversible**: You can decode the hash back to the original numbers
# 3. **Non-sequential**: Sequential numbers don't produce sequential hashes
# 4. **Customizable**: Uses a salt, minimum length, alphabet, and optional blocklist
#
# === Core Algorithm Concepts:
#
# The algorithm works by:
# - Converting each integer to a custom base-N representation using a shuffled alphabet
# - The alphabet permutation is deterministic based on a "lottery" character and salt
# - A lottery character is chosen based on a hash of the input numbers
# - Each number is encoded with a different alphabet permutation (for obfuscation)
# - Separators divide encoded numbers, and guards are added for minimum length
# - The decode process reverses this by extracting the lottery, splitting on separators,
#   and converting each segment back from the custom base-N representation
#
# === Character Sets:
#
# - **Alphabet**: Main characters used to encode numbers (after setup, doesn't include separators/guards)
# - **Separators**: Characters that separate encoded number segments within a hash
# - **Guards**: Special characters added at boundaries to meet minimum length requirements
# - All three sets are disjoint (no overlap) after initialization
#
# === Why This Design?
#
# The shuffling and lottery system ensures that:
# - Similar numbers produce very different hashes (no sequential patterns)
# - Each position in a multi-number sequence uses a different encoding
# - The hash obfuscates the inputs if the salt is unknown
# - The same numbers always produce the same hash (deterministic)

module EncodedId
  module Encoders
    # Implementation of HashId, optimised and adapted from the original `hashid.rb` gem
    class Hashid
      include HashidConsistentShuffle

      # @rbs @separators_and_guards: HashidOrdinalAlphabetSeparatorGuards
      # @rbs @alphabet_ordinals: Array[Integer]
      # @rbs @separator_ordinals: Array[Integer]
      # @rbs @guard_ordinals: Array[Integer]
      # @rbs @salt_ordinals: Array[Integer]
      # @rbs @escaped_separator_selector: String
      # @rbs @escaped_guards_selector: String

      # Initialize a new HashId encoder with custom parameters.
      #
      # The initialization process sets up the character sets (alphabet, separators, guards)
      # that will be used for encoding and decoding. These character sets are:
      # 1. Shuffled based on the salt for uniqueness
      # 2. Balanced in ratios (alphabet:separators ≈ 3.5:1, alphabet:guards ≈ 12:1)
      # 3. Made disjoint (no character appears in multiple sets)
      #
      # @param salt [String] Secret salt used to shuffle the alphabet (empty string is valid)
      # @param min_hash_length [Integer] Minimum length of generated hashes (0 for no minimum)
      # @param alphabet [Alphabet] Character set to use for encoding
      # @param blocklist [Blocklist?] Optional list of words that shouldn't appear in hashes
      # @param blocklist_mode [Symbol] Mode for blocklist checking (:always, :length_threshold, :raise_if_likely)
      # @param blocklist_max_length [Integer] Maximum ID length for blocklist checking (when mode is :length_threshold)
      #
      # @rbs (String salt, ?Integer min_hash_length, ?Alphabet alphabet, ?Blocklist? blocklist, ?Symbol blocklist_mode, ?Integer blocklist_max_length) -> void
      def initialize(salt, min_hash_length = 0, alphabet = Alphabet.alphanum, blocklist = nil, blocklist_mode = :length_threshold, blocklist_max_length = 32)
        unless min_hash_length.is_a?(Integer) && min_hash_length >= 0
          raise ArgumentError, "The min length must be a Integer and greater than or equal to 0"
        end
        @min_hash_length = min_hash_length
        @salt = salt
        @alphabet = alphabet
        @blocklist = blocklist
        @blocklist_mode = blocklist_mode
        @blocklist_max_length = blocklist_max_length

        @separators_and_guards = HashidOrdinalAlphabetSeparatorGuards.new(alphabet, salt)
        @alphabet_ordinals = @separators_and_guards.alphabet
        @separator_ordinals = @separators_and_guards.seps
        @guard_ordinals = @separators_and_guards.guards
        @salt_ordinals = @separators_and_guards.salt

        # Pre-compute escaped versions for use with String#tr during decoding.
        # This escapes special regex characters like '-', '\\', and '^' for safe use in tr().
        @escaped_separator_selector = @separators_and_guards.seps_tr_selector
        @escaped_guards_selector = @separators_and_guards.guards_tr_selector
      end

      attr_reader :alphabet_ordinals #: Array[Integer]
      attr_reader :separator_ordinals #: Array[Integer]
      attr_reader :guard_ordinals #: Array[Integer]
      attr_reader :salt_ordinals #: Array[Integer]
      attr_reader :salt #: String
      attr_reader :alphabet #: Alphabet
      attr_reader :blocklist #: Blocklist?
      attr_reader :min_hash_length #: Integer

      # Encode an array of non-negative integers into a hash string.
      #
      # The encoding process:
      # 1. Validates all numbers are integers and non-negative
      # 2. Calculates a "lottery" character based on the input numbers
      # 3. For each number, shuffles the alphabet and encodes the number in that custom base
      # 4. Inserts separator characters between encoded numbers
      # 5. Adds guards and padding if needed to meet minimum length
      # 6. Validates the result doesn't contain blocklisted words
      #
      # @param numbers [Array<Integer>] Array of non-negative integers to encode
      # @return [String] The encoded hash string (empty if input is empty or contains negatives)
      # @raise [BlocklistError] If the generated hash contains a blocklisted word
      #
      # @rbs (Array[Integer] numbers) -> String
      def encode(numbers)
        numbers.all? { |n| Integer(n) }

        return "" if numbers.empty? || numbers.any? { |n| n < 0 }

        encoded = internal_encode(numbers)
        if should_check_blocklist?(encoded)
          blocked_word = contains_blocklisted_word?(encoded)
          if blocked_word
            raise EncodedId::BlocklistError, "Generated ID '#{encoded}' contains blocklisted word: '#{blocked_word}'"
          end
        end

        encoded
      end

      # Decode a hash string back into an array of integers.
      #
      # The decoding process:
      # 1. Removes guards by replacing them with spaces and splitting
      # 2. Extracts the lottery character (first character after guard removal)
      # 3. Splits on separators to get individual encoded number segments
      # 4. For each segment, shuffles the alphabet the same way as encoding and decodes
      # 5. Verifies by re-encoding the result and comparing to the original hash
      #
      # This verification step is critical for valid decoding: it ensures that random strings
      # won't decode to valid numbers. Only properly encoded hashes will pass.
      #
      # @param hash [String] The hash string to decode
      # @return [Array<Integer>] Array of decoded integers (empty if hash is invalid)
      #
      # @rbs (String hash) -> Array[Integer]
      def decode(hash)
        return [] if hash.nil? || hash.empty?

        internal_decode(hash)
      end

      private

      # Internal encoding implementation - converts numbers to a hash string.
      #
      # Algorithm steps:
      #
      # Step 1: Calculate the "lottery" character
      #   - Create a hash_int from the input numbers (weighted sum: num % (index + 100))
      #   - Use hash_int to pick a lottery character from the alphabet
      #   - The lottery becomes the first character and seeds all alphabet shuffles
      #
      # Step 2: Encode each number
      #   - For each number:
      #     a. Shuffle alphabet using (lottery + salt) as the shuffle key
      #     b. Convert number to custom base-N using shuffled alphabet (via hash_one_number)
      #     c. Insert a separator character between numbers (chosen deterministically)
      #   - Each number gets a different alphabet permutation due to the shuffle
      #
      # Step 3: Add guards if below minimum length
      #   - Guards are special boundary characters that don't encode data
      #   - First guard is prepended based on (hash_int + first_char)
      #   - Second guard is appended based on (hash_int + third_char)
      #
      # Step 4: Pad with alphabet if still below minimum length
      #   - Shuffle the alphabet using itself as the key
      #   - Wrap the hash with the shuffled alphabet (second half + hash + first half)
      #   - Trim excess from the middle if we overshoot the target length
      #
      # The result is a string where:
      # - Structure: [guard?] lottery encoded_num1 sep encoded_num2 sep ... [guard?] [padding?]
      # - Each component is deterministic based on the input numbers and salt
      # - Similar inputs produce very different outputs due to the lottery system
      #
      # @param numbers [Array<Integer>] Non-negative integers to encode
      # @return [String] The encoded hash string
      #
      # @rbs (Array[Integer] numbers) -> String
      def internal_encode(numbers)
        current_alphabet = @alphabet_ordinals.dup
        separator_ordinals = @separator_ordinals
        guard_ordinals = @guard_ordinals

        alphabet_length = current_alphabet.length
        length = numbers.length

        # Step 1: Calculate lottery character using a weighted hash of all input numbers.
        # The modulo (i + 100) ensures different positions contribute differently to the hash.
        # We use a manual loop instead of Array#sum to avoid extra array allocation.
        hash_int = 0
        i = 0
        while i < length
          hash_int += numbers[i] % (i + 100)
          i += 1
        end

        # The lottery character is chosen deterministically from the alphabet.
        # This becomes the first character of the hash AND the seed for all shuffles.
        lottery = current_alphabet[hash_int % alphabet_length]

        # This array will hold the final hash as character ordinals (codepoints).
        # @type var hashid_code: Array[Integer]
        hashid_code = []
        hashid_code << lottery

        # The "seasoning" is the shuffle key: lottery + salt.
        # This same seasoning will be used to shuffle the alphabet for each number.
        seasoning = [lottery].concat(@salt_ordinals)

        # Reusable buffer for the pre-shuffle alphabet state to avoid allocations in the loop.
        alphabet_buffer = current_alphabet.dup

        # Step 2: Encode each number with its own alphabet permutation.
        i = 0
        while i < length
          num = numbers[i]

          # Shuffle the alphabet using the seasoning. This is deterministic but produces
          # a different permutation than the original alphabet. Since we reshuffle on each
          # iteration with the same key, we need to pass the pre-shuffle state as salt_part_2.
          alphabet_buffer.replace(current_alphabet)
          consistent_shuffle!(current_alphabet, seasoning, alphabet_buffer, alphabet_length)

          # Convert this number to base-N using the current shuffled alphabet.
          last_char_ord = hash_one_number(hashid_code, num, current_alphabet, alphabet_length)

          # Add a separator between numbers (but not after the last number).
          # The separator is chosen deterministically based on the encoded number and position.
          if (i + 1) < length
            num %= (last_char_ord + i)
            hashid_code << separator_ordinals[num % separator_ordinals.length]
          end

          i += 1
        end

        # Step 3: Add guards if we're below the minimum length.
        # Guards are boundary markers chosen deterministically from the guard set.
        if hashid_code.length < @min_hash_length
          # Prepend first guard based on hash_int and the lottery character.
          guard_count = guard_ordinals.length
          first_char = hashid_code[0] #: Integer
          hashid_code.prepend(guard_ordinals[(hash_int + first_char) % guard_count])

          # If still too short, append second guard based on hash_int and third character.
          if hashid_code.length < @min_hash_length
            # At this point hashid_code has at least 2 elements (lottery + guard), check for 3rd
            third_char = hashid_code[2]
            hashid_code << if third_char
              guard_ordinals[(hash_int + third_char) % guard_count]
            else
              # If no third character exists, use 0 as default
              guard_ordinals[hash_int % guard_count]
            end
          end
        end

        # Step 4: Pad with shuffled alphabet if still below minimum length.
        half_length = alphabet_length.div(2)

        while hashid_code.length < @min_hash_length
          # Shuffle the alphabet using itself as the key (creates a new permutation).
          consistent_shuffle!(current_alphabet, current_alphabet.dup, nil, alphabet_length)

          # Wrap the hash: second_half + hash + first_half
          second_half = current_alphabet[half_length..] #: Array[Integer]
          first_half = current_alphabet[0, half_length] #: Array[Integer]
          hashid_code.prepend(*second_half)
          hashid_code.concat(first_half)

          # If we've overshot the target, trim excess from the middle.
          excess = hashid_code.length - @min_hash_length
          if excess > 0
            hashid_code = hashid_code[excess / 2, @min_hash_length] #: Array[Integer]
          end
        end

        # Convert the array of character ordinals to a UTF-8 string.
        hashid_code.pack("U*")
      end

      # Internal decoding implementation - converts a hash string back to numbers.
      #
      # Algorithm steps:
      #
      # Step 1: Remove guards
      #   - Replace all guard characters with spaces and split
      #   - Guards can appear at positions [0] or [0] and [-1]
      #   - If array has 2 or 3 elements, the middle one contains the actual hash
      #   - Otherwise, element [0] contains the hash
      #
      # Step 2: Extract lottery and split on separators
      #   - First character is the lottery (same as during encoding)
      #   - Replace separator characters with spaces and split
      #   - Each segment is an encoded number
      #
      # Step 3: Decode each number
      #   - For each segment:
      #     a. Shuffle alphabet using (lottery + salt) - same as encoding
      #     b. Convert from custom base-N back to integer (via unhash)
      #   - The alphabet shuffles must match the encoding shuffles exactly
      #
      # Step 4: Verify the result
      #   - Re-encode the decoded numbers and compare to original hash
      #   - If they don't match, return empty array
      #   - This prevents random strings from decoding to valid numbers
      #
      # @param hash [String] The hash string to decode
      # @return [Array<Integer>] Decoded integers (empty if hash is invalid)
      #
      # @rbs (String hash) -> Array[Integer]
      def internal_decode(hash)
        # @type var ret: Array[Integer]
        ret = []
        current_alphabet = @alphabet_ordinals.dup
        salt_ordinals = @salt_ordinals

        # Step 1: Remove guards by replacing them with spaces and splitting.
        # This separates the actual hash from any guard characters that were added.
        breakdown = hash.tr(@escaped_guards_selector, " ")
        array = breakdown.split(" ")

        # If guards were present, the hash will be in the middle segment.
        # - Length 1: No guards, hash is at [0]
        # - Length 2: One guard, hash is at [1]
        # - Length 3: Two guards, hash is at [1]
        i = [3, 2].include?(array.length) ? 1 : 0

        if (breakdown = array[i])
          # Step 2: Extract the lottery character (first char) and the rest.
          lottery = breakdown[0] #: String
          remainder = breakdown[1..] || "" #: String

          # Replace separator characters with spaces and split to get individual encoded numbers.
          remainder.tr!(@escaped_separator_selector, " ")
          sub_hashes = remainder.split(" ")

          # Create the same seasoning used during encoding: lottery + salt.
          seasoning = [lottery.ord].concat(salt_ordinals)

          # Step 3: Decode each number segment.
          len = sub_hashes.length
          time = 0
          while time < len
            sub_hash = sub_hashes[time]

            # Shuffle the alphabet exactly as we did during encoding.
            # This must produce the same permutation to correctly decode.
            consistent_shuffle!(current_alphabet, seasoning, current_alphabet.dup, current_alphabet.length)

            # Convert this segment from base-N back to an integer.
            ret.push unhash(sub_hash, current_alphabet)
            time += 1
          end

          # Step 4: Verify by re-encoding and comparing.
          # This is critical for validity: it ensures only valid hashes decode successfully.
          if encode(ret) != hash
            # @type var ret: Array[Integer]
            ret = []
          end
        end

        ret
      end

      # Convert a single integer to its representation in a custom base-N system.
      #
      # This is similar to converting a decimal number to binary, hex, etc., but:
      # - Uses a custom alphabet instead of 0-9 or 0-9A-F
      # - The alphabet can be any length (base-N where N = alphabet.length)
      # - Characters are inserted in reverse order (most significant digit last)
      #
      # Example: Converting 123 to base-10 with alphabet ['a','b','c','d','e','f','g','h','i','j']
      # - 123 % 10 = 3 → 'd' (index 3)
      # - 12 % 10 = 2 → 'c' (index 2)
      # - 1 % 10 = 1 → 'b' (index 1)
      # - Result: "bcd" (but inserted in reverse, so appears as "bcd" in hash_code)
      #
      # @param hash_code [Array<Integer>] The array to append characters to (modified in place)
      # @param num [Integer] The number to convert
      # @param alphabet [Array<Integer>] The alphabet ordinals to use for encoding
      # @param alphabet_length [Integer] Length of the alphabet (cached for performance)
      # @return [Integer] The ordinal of the last character added
      #
      # @rbs (Array[Integer] hash_code, Integer num, Array[Integer] alphabet, Integer alphabet_length) -> Integer
      def hash_one_number(hash_code, num, alphabet, alphabet_length)
        char = 0 #: Integer
        insert_at = 0

        # Convert number to base-N by repeatedly dividing by alphabet_length.
        # Insert characters at the end (using negative index) so they appear in correct order.
        while true # standard:disable Style/InfiniteLoop
          char = alphabet[num % alphabet_length] || 0
          insert_at -= 1
          hash_code.insert(insert_at, char)
          num /= alphabet_length
          break unless num > 0
        end

        char
      end

      # Convert a custom base-N encoded string back to an integer.
      #
      # This is the inverse of hash_one_number. It treats the input string as a number
      # in a custom base where each character's position in the alphabet represents its digit value.
      #
      # Example: Decoding "bcd" with alphabet ['a','b','c','d','e','f','g','h','i','j'] (base-10)
      # - 'b' at position 1: 1 × 10² = 100
      # - 'c' at position 2: 2 × 10¹ = 20
      # - 'd' at position 3: 3 × 10⁰ = 3
      # - Result: 100 + 20 + 3 = 123
      #
      # @param input [String] The encoded string to decode
      # @param alphabet [Array<Integer>] The alphabet ordinals used for encoding
      # @return [Integer] The decoded number
      # @raise [InvalidInputError] If input contains characters not in the alphabet
      #
      # @rbs (String input, Array[Integer] alphabet) -> Integer
      def unhash(input, alphabet)
        num = 0 #: Integer
        input_length = input.length
        alphabet_length = alphabet.length
        i = 0

        # Process each character from left to right (most significant to least).
        while i < input_length
          first_char = input[i] #: String
          pos = alphabet.index(first_char.ord)
          raise InvalidInputError, "unable to unhash" unless pos

          # Calculate this digit's contribution: position_in_alphabet × base^exponent
          exponent = input_length - i - 1
          multiplier = alphabet_length**exponent #: Integer
          num += pos * multiplier
          i += 1
        end

        num
      end

      # Check if the encoded string contains any blocklisted words.
      #
      # Determines if blocklist checking should be performed based on mode and ID length
      #
      # @param encoded_string [String] The encoded ID to check
      # @return [Boolean] True if blocklist should be checked
      #
      # @rbs (String encoded_string) -> bool
      def should_check_blocklist?(encoded_string)
        return false unless @blocklist && !@blocklist.empty?

        case @blocklist_mode
        when :always
          true
        when :length_threshold
          encoded_string.length <= @blocklist_max_length
        when :raise_if_likely
          # This mode raises at configuration time, so if we get here, we check
          true
        else
          true
        end
      end

      # @param encoded_string [String] The encoded hash to check
      # @return [String, false] The blocklisted word if found, false otherwise
      #
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
