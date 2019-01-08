# frozen_string_literal: true

# Hashid with Crockford alphabet and split into 4x4 set
module Core
  class ReversableId
    class << self
      delegate :encode, :decode, to: :new
    end

    def initialize(salt: "lha83hk73y9r3jp9js98ugo84", hash_length: 16, alphabet: "0123456789abcdefghjkmnpqrstvwxyz")
      # https://www.crockford.com/wrmg/base32.html
      @human_friendly_alphabet = alphabet
      @salt = salt
      @hash_length = hash_length
    end

    # Encode the input values into a hash
    def encode(*values)
      convert_to_string(uid_generator.encode(*values))
    end

    # Decode the hash to original array
    def decode(str)
      uid_generator.decode(convert_to_hash(str))
    end

    private

    attr_reader :salt, :hash_length, :human_friendly_alphabet

    def uid_generator
      @uid_generator ||= Hashids.new(salt, hash_length, human_friendly_alphabet)
    end

    def convert_to_string(hash)
      hash_s = hash.is_a?(Array) ? hash.join : hash.to_s
      hash_s.chars
            .each_slice(4)
            .map(&:join)
            .join("-")
    end

    def convert_to_hash(str)
      map_crockford_set(str.delete("-").downcase)
    end

    def map_crockford_set(str)
      str.tr("o", "0").tr("l", "1").tr("i", "1")
    end
  end
end
