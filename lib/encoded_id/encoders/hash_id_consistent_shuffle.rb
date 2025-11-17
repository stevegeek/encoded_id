# frozen_string_literal: true
# rbs_inline: enabled

module EncodedId
  module Encoders
    class HashIdConsistentShuffle
      # @rbs (Array[Integer] collection_to_shuffle, Array[Integer] salt_part_1, Array[Integer]? salt_part_2, Integer max_salt_length) -> Array[Integer]
      def self.shuffle!(collection_to_shuffle, salt_part_1, salt_part_2, max_salt_length)
        salt_part_1_length = salt_part_1.length
        raise SaltError, "Salt is too short in shuffle" if salt_part_1_length < max_salt_length && salt_part_2.nil?

        return collection_to_shuffle if collection_to_shuffle.empty? || max_salt_length == 0 || salt_part_1.nil? || salt_part_1_length == 0

        idx = ord_total = 0
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
          ord_total += n
          j = (n + idx + ord_total) % i

          collection_to_shuffle[i], collection_to_shuffle[j] = collection_to_shuffle[j], collection_to_shuffle[i]

          idx = (idx + 1) % max_salt_length
          i -= 1
        end

        collection_to_shuffle
      end
    end
  end
end
