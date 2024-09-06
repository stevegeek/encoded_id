# frozen_string_literal: true

module EncodedId
  class HashIdConsistentShuffle
    def self.call(collection_to_shuffle, salt_part_1, salt_part_2, max_salt_length)
      salt_part_1_length = salt_part_1.length
      raise SaltError, "Salt is too short in shuffle" if salt_part_1_length < max_salt_length && salt_part_2.nil?

      return collection_to_shuffle if collection_to_shuffle.empty? || max_salt_length == 0 || salt_part_1.nil? || salt_part_1_length == 0

      chars = collection_to_shuffle.dup

      idx = ord_total = 0
      i = collection_to_shuffle.length - 1
      while i >= 1
        n = (idx >= salt_part_1_length) ? salt_part_2[idx - salt_part_1_length] : salt_part_1[idx]
        ord_total += n
        j = (n + idx + ord_total) % i

        chars[i], chars[j] = chars[j], chars[i]

        idx = (idx + 1) % max_salt_length
        i -= 1
      end

      chars
    end
  end
end
