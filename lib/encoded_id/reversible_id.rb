# frozen_string_literal: true

require "hashids"

# Hashid with a reduced character set Crockford alphabet and split groups
# See: https://www.crockford.com/wrmg/base32.html
# Build with https://hashids.org
# Note hashIds already has a built in profanity limitation algorithm
module EncodedId
  class ReversibleId
    ALPHABET = "0123456789abcdefghjkmnpqrstuvwxyz"

    def initialize(salt:, length: 8, split_at: 4, alphabet: ALPHABET)
      unique_alphabet = alphabet.chars.uniq
      raise InvalidAlphabetError, "Alphabet must be at least 16 characters" if unique_alphabet.size < 16

      @human_friendly_alphabet = unique_alphabet.join
      @salt = salt
      @length = length
      @split_at = split_at
    end

    # Encode the input values into a hash
    def encode(*values)
      uid = convert_to_string(uid_generator.encode(*values))
      uid = humanize_length(uid) unless split_at.nil?
      uid
    end

    # Decode the hash to original array
    def decode(str)
      uid_generator.decode(convert_to_hash(str))
    rescue ::Hashids::InputError => e
      raise EncodedIdFormatError, e.message
    end

    private

    attr_reader :salt, :length, :human_friendly_alphabet, :split_at

    def uid_generator
      @uid_generator ||= ::Hashids.new(salt, length, human_friendly_alphabet)
    end

    def convert_to_string(hash)
      hash.is_a?(Array) ? hash.join : hash.to_s
    end

    def split_regex
      @split_regex ||= /.{#{split_at}}(?=.)/
    end

    def humanize_length(hash)
      hash.gsub(split_regex, '\0-')
    end

    def convert_to_hash(str)
      map_crockford_set(str.delete("-").downcase)
    end

    def map_crockford_set(str)
      # Crockford suggest i==1 , but I think i==j is more appropriate as we
      # only use lowercase
      str.tr("o", "0").tr("l", "1").tr("i", "j")
    end
  end
end
