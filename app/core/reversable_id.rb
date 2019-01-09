# frozen_string_literal: true

# Hashid with a profanity safer reduced character set Crockford alphabet and split into 4 x 4 groups
# See: https://www.crockford.com/wrmg/base32.html
# See: https://www.fiznool.com/blog/2014/11/16/short-id-generation-in-javascript/
module Core
  class ReversableId
    ALPHABET = "0123456789abdegjkmnpqrvwxyz"

    class << self
      delegate :encode, :decode, to: :new
    end

    def initialize(salt: PlatformConfig::App.uid_salt, length: 16, alphabet: Core::ReversableId::ALPHABET)
      @human_friendly_alphabet = alphabet
      @salt = salt
      @length = length
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

    attr_reader :salt, :length, :human_friendly_alphabet

    def uid_generator
      @uid_generator ||= Hashids.new(salt, length, human_friendly_alphabet)
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
