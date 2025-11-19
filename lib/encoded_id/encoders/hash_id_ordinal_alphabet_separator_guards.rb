# frozen_string_literal: true

# rbs_inline: enabled

module EncodedId
  module Encoders
    # Prepares and partitions the character sets for HashID encoding.
    #
    # This class is responsible for splitting a single input alphabet into three disjoint sets:
    # 1. **Alphabet**: Main characters used to encode numbers
    # 2. **Separators (seps)**: Characters that separate encoded numbers in the hash
    # 3. **Guards**: Characters added at boundaries to meet minimum length requirements
    #
    # == Initialization Process:
    #
    # Step 1: Start with default separators ("cfhistuCFHISTU")
    # Step 2: Ensure separators and alphabet are disjoint (remove overlaps)
    # Step 3: Shuffle separators using the salt
    # Step 4: Balance alphabet-to-separator ratio (target ≈ 3.5:1)
    # Step 5: Create guards from alphabet or separators (target ≈ 12:1 alphabet-to-guards)
    # Step 6: Shuffle alphabet using the salt
    #
    # == Character Set Ratios:
    #
    # The algorithm maintains specific ratios between the character sets:
    # - Alphabet : Separators ≈ 3.5 : 1 (SEP_DIV)
    # - Alphabet : Guards ≈ 12 : 1 (GUARD_DIV)
    #
    # These ratios ensure:
    # - Enough separators to avoid patterns in multi-number hashes
    # - Guards are rare enough to not waste space but common enough to be useful
    # - Alphabet is large enough for efficient encoding (shorter hashes)
    #
    # == Why Ordinals?
    #
    # All characters are stored as integer ordinals (Unicode codepoints) rather than strings.
    # This provides:
    # - Faster comparisons and lookups
    # - More efficient memory usage
    # - Direct array indexing without string allocations
    #
    class HashIdOrdinalAlphabetSeparatorGuards
      include HashIdConsistentShuffle

      # Target ratio of alphabet to separators (alphabet.length / seps.length ≈ 3.5)
      SEP_DIV = 3.5

      # Default separator characters - chosen to be visually distinct and common in many fonts
      DEFAULT_SEPS = "cfhistuCFHISTU".chars.map(&:ord).freeze

      # Target ratio of alphabet to guards (alphabet.length / guards.length ≈ 12)
      GUARD_DIV = 12.0

      # Space character ordinal - used as a placeholder when removing characters
      SPACE_CHAR = " ".ord

      # @rbs @alphabet: Array[Integer]
      # @rbs @salt: Array[Integer]
      # @rbs @seps: Array[Integer]
      # @rbs @guards: Array[Integer]
      # @rbs @seps_tr_selector: String
      # @rbs @guards_tr_selector: String

      # Initialize and partition the character sets.
      #
      # Takes an alphabet and salt, then:
      # 1. Converts all characters to ordinals (integer codepoints)
      # 2. Partitions the alphabet into separators, guards, and the remaining alphabet
      # 3. Shuffles each set deterministically using the salt
      # 4. Balances the ratios between the sets
      # 5. Creates escaped versions for use with String#tr
      #
      # All arrays are frozen after setup to prevent accidental modification.
      #
      # @param alphabet [Alphabet] The character set to partition
      # @param salt [String] The salt used for shuffling
      #
      # @rbs (Alphabet alphabet, String salt) -> void
      def initialize(alphabet, salt)
        # Convert alphabet and salt to arrays of ordinals (integer codepoints).
        @alphabet = alphabet.characters.chars.map(&:ord)
        @salt = salt.chars.map(&:ord)

        # Partition the alphabet into separators and alphabet.
        # This ensures they're disjoint and properly balanced.
        setup_seps

        # Extract guards from either separators or alphabet.
        # Guards are boundary markers used for minimum length padding.
        setup_guards

        # Pre-compute escaped versions for String#tr operations during decode.
        # This escapes special characters like '-', '\\', and '^' that have
        # special meaning in tr() character ranges.
        @seps_tr_selector = escape_characters_string_for_tr(@seps.map(&:chr))
        @guards_tr_selector = escape_characters_string_for_tr(@guards.map(&:chr))

        # Freeze all arrays to prevent accidental modification.
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

      # Escape special characters for safe use in String#tr.
      #
      # String#tr treats certain characters specially:
      # - '-' : Defines character ranges (e.g., 'a-z')
      # - '\\' : Escape character
      # - '^' : Negation when at the start
      #
      # This method escapes these characters so they're treated literally.
      #
      # Example: ['a', '-', 'z'] → "a\\-z" (not a range from a to z)
      #
      # @param chars [Array<String>] Characters to join and escape
      # @return [String] Escaped string safe for use in tr()
      #
      # @rbs (Array[String] chars) -> String
      def escape_characters_string_for_tr(chars)
        chars.join.gsub(/([-\\^])/) { "\\#{$1}" }
      end

      # Setup and partition separators from the alphabet.
      #
      # This method:
      # 1. Starts with default separators ("cfhistuCFHISTU")
      # 2. Makes alphabet and separators disjoint (removes overlaps)
      # 3. Removes any space characters that may have been introduced
      # 4. Shuffles separators using the salt
      # 5. Balances the alphabet-to-separator ratio to approximately 3.5:1
      # 6. Shuffles the final alphabet using the salt
      #
      # The ratio balancing ensures:
      # - If there are too few separators, take some from the alphabet
      # - If there are too many separators, trim the excess
      # - Minimum of 2 separators is maintained
      #
      # @rbs () -> void
      def setup_seps
        @seps = DEFAULT_SEPS.dup

        # Make alphabet and separators disjoint.
        # For each separator:
        # - If it exists in the alphabet, remove it from the alphabet
        # - If it doesn't exist in the alphabet, remove it from separators
        # This ensures separators only contains characters from the original alphabet.
        @seps.length.times do |sep_index|
          if (alphabet_index = @alphabet.index(@seps[sep_index]))
            # Separator exists in alphabet - remove it from alphabet.
            @alphabet = remove_character_at(@alphabet, alphabet_index)
          else
            # Separator doesn't exist in alphabet - remove it from separators.
            @seps = remove_character_at(@seps, sep_index)
          end
        end

        # Remove any space characters introduced by remove_character_at.
        # Spaces are placeholders and shouldn't appear in the final sets.
        @alphabet.delete(SPACE_CHAR)
        @seps.delete(SPACE_CHAR)

        # Shuffle separators deterministically using the salt.
        salt_length = @salt.length
        consistent_shuffle!(@seps, @salt, nil, salt_length)

        # Balance the alphabet-to-separator ratio to approximately SEP_DIV (3.5:1).
        # This ensures we have enough separators for good distribution in multi-number hashes.
        alphabet_length = @alphabet.length
        seps_count = @seps.length
        if seps_count == 0 || (alphabet_length / seps_count.to_f) > SEP_DIV
          # Calculate target separator count based on alphabet size.
          seps_target_count = (alphabet_length / SEP_DIV).ceil
          seps_target_count = 2 if seps_target_count == 1 # Minimum 2 separators

          if seps_target_count > seps_count
            # Not enough separators - take some from the alphabet.
            diff = seps_target_count - seps_count

            # These are safe: diff > 0 and @alphabet has enough elements by design
            additonal_seps = @alphabet[0, diff] #: Array[Integer]
            @seps += additonal_seps
            @alphabet = @alphabet[diff..] #: Array[Integer]
          else
            # Too many separators - trim to target length.
            @seps = @seps[0, seps_target_count] #: Array[Integer]
          end
        end

        # Shuffle the final alphabet deterministically using the salt.
        # This ensures different salts produce different alphabet orderings.
        consistent_shuffle!(@alphabet, @salt, nil, salt_length)
      end

      # Setup guards by extracting them from separators or alphabet.
      #
      # Guards are special boundary characters used for minimum length padding.
      # They're chosen from either the separator set or alphabet based on alphabet size:
      #
      # - If alphabet is very small (< 3 characters): Take guards from separators
      # - Otherwise: Take guards from alphabet
      #
      # The number of guards is calculated to maintain approximately a 12:1 ratio
      # with the alphabet (alphabet.length / GUARD_DIV).
      #
      # Why this matters:
      # - Guards don't encode data, so we want them to be rare
      # - But we need enough variety to avoid patterns in minimum-length hashes
      # - Taking from separators when alphabet is small preserves encoding characters
      #
      # @rbs () -> void
      def setup_guards
        # Calculate target guard count: approximately 1/12th of alphabet length.
        alphabet_length = @alphabet.length
        gc = (alphabet_length / GUARD_DIV).ceil

        if alphabet_length < 3
          # Very small alphabet - take guards from separators to preserve alphabet.
          @guards = @seps[0, gc] #: Array[Integer]
          @seps = @seps[gc..] || [] #: Array[Integer]
        else
          # Normal case - take guards from alphabet.
          @guards = @alphabet[0, gc] #: Array[Integer]
          @alphabet = @alphabet[gc..] || [] #: Array[Integer]
        end
      end

      # Remove a character from an array by replacing it with a space.
      #
      # This is used during the separator/alphabet disjoint operation.
      # Instead of mutating the array in place, it creates a new array with:
      # - All characters before the index
      # - A SPACE_CHAR placeholder
      # - All characters after the index
      #
      # The space acts as a placeholder that gets removed later by Array#delete.
      # This approach maintains array indices during iteration.
      #
      # Example:
      #   remove_character_at([97, 98, 99], 1) → [97, 32, 99]  # [a, space, c]
      #
      # @param array [Array<Integer>] The array to remove from
      # @param index [Integer] The index of the character to remove
      # @return [Array<Integer>] New array with character replaced by space
      #
      # @rbs (Array[Integer] array, Integer index) -> Array[Integer]
      def remove_character_at(array, index)
        tail = array[index + 1..]
        head = array[0, index] || []
        head << SPACE_CHAR
        tail ? head + tail : head
      end

    end
  end
end
