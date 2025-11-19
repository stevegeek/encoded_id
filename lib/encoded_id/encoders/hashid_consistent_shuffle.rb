# frozen_string_literal: true

# rbs_inline: enabled

module EncodedId
  module Encoders
    # Implements a deterministic, salt-based shuffle algorithm for HashIDs.
    #
    # This is the core obfuscation mechanism that makes HashIDs non-sequential.
    # The algorithm has several critical properties:
    #
    # 1. **Deterministic**: Same input + same salt = same output (always)
    # 2. **Reversible**: The shuffle can be undone if needed
    # 3. **Salt-dependent**: Different salts produce different permutations
    # 4. **Consistent**: Multiple calls with the same salt produce the same shuffle
    #
    # == Algorithm Overview:
    #
    # The shuffle works by:
    # - Walking backwards through the collection (from last to second element)
    # - For each position i, selecting a swap partner j using the salt
    # - The swap position is calculated from: (salt_char + index + running_total) % i
    # - Cycling through salt characters, wrapping when we reach the end
    #
    # This is similar to a Fisher-Yates shuffle, but with deterministic swap positions
    # derived from the salt rather than random numbers.
    #
    # == Why Two Salt Parts?
    #
    # The algorithm accepts salt in two parts (salt_part_1 and salt_part_2) to support
    # scenarios where the salt is constructed from multiple sources:
    # - salt_part_1: Primary salt (e.g., lottery + user salt)
    # - salt_part_2: Secondary salt (e.g., pre-shuffle alphabet copy)
    #
    # When cycling through salt characters, it reads from salt_part_1 first, then
    # salt_part_2 if the index exceeds salt_part_1's length.
    #
    # == Example:
    #
    # Input: [1, 2, 3, 4], salt: [65, 66, 67] (ABC)
    # Step 1: i=3, salt[0]=65, ord_total=0   → swap positions 3 and ((65+0+0)%3=2)  → [1,2,4,3]
    # Step 2: i=2, salt[1]=66, ord_total=65  → swap positions 2 and ((66+1+65)%2=0) → [4,2,1,3]
    # Step 3: i=1, salt[2]=67, ord_total=131 → swap positions 1 and ((67+2+131)%1=0)→ [4,2,1,3]
    # Result: [4, 2, 1, 3]
    #
    module HashidConsistentShuffle
      # Deterministically shuffle a collection based on a salt.
      #
      # Shuffles the collection in place using a salt-based algorithm that produces
      # consistent results for the same inputs.
      #
      # @param collection_to_shuffle [Array<Integer>] Array to shuffle (modified in place)
      # @param salt_part_1 [Array<Integer>] Primary salt characters (as ordinals)
      # @param salt_part_2 [Array<Integer>?] Optional secondary salt characters
      # @param max_salt_length [Integer] Maximum salt length to use (for cycling)
      # @return [Array<Integer>] The shuffled array (same object as input)
      # @raise [SaltError] If salt is too short or shuffle fails
      #
      # @rbs (Array[Integer] collection_to_shuffle, Array[Integer] salt_part_1, Array[Integer]? salt_part_2, Integer max_salt_length) -> Array[Integer]
      def consistent_shuffle!(collection_to_shuffle, salt_part_1, salt_part_2, max_salt_length)
        salt_part_1_length = salt_part_1.length

        # Validate we have enough salt. If max_salt_length exceeds salt_part_1,
        # we need salt_part_2 to provide the additional characters.
        raise SaltError, "Salt is too short in shuffle" if salt_part_1_length < max_salt_length && salt_part_2.nil?

        # Short-circuit if there's nothing to shuffle.
        return collection_to_shuffle if collection_to_shuffle.empty? || max_salt_length == 0 || salt_part_1.nil? || salt_part_1_length == 0

        # idx: Current position in the salt (cycles through 0..max_salt_length-1)
        # ord_total: Running sum of salt character ordinals (affects swap positions)
        idx = ord_total = 0

        # Walk backwards through the collection from last to second element.
        # We don't shuffle the first element (i=0) because it has nowhere to swap to.
        i = collection_to_shuffle.length - 1
        while i >= 1
          # Get the current salt character ordinal.
          # If we've exceeded salt_part_1, read from salt_part_2.
          n = if idx >= salt_part_1_length
            raise SaltError, "Salt shuffle has failed" unless salt_part_2

            salt_part_2[idx - salt_part_1_length]
          else
            salt_part_1[idx]
          end

          # Update running total with current salt character.
          ord_total += n

          # Calculate swap position deterministically from:
          # - n: Current salt character ordinal
          # - idx: Current position in salt
          # - ord_total: Running sum of all salt characters used so far
          # - i: Current position in collection (modulo to ensure valid index)
          j = (n + idx + ord_total) % i

          # Swap elements at positions i and j.
          collection_to_shuffle[i], collection_to_shuffle[j] = collection_to_shuffle[j], collection_to_shuffle[i]

          # Move to next salt character (wrapping around if needed).
          idx = (idx + 1) % max_salt_length
          i -= 1
        end

        collection_to_shuffle
      end
    end
  end
end
