# frozen_string_literal: true

module EncodedId
  class HashIdSalt
    def initialize(salt)
      unless salt.is_a?(String)
        raise SaltError, "The salt must be a String"
      end
      @salt = salt.freeze
      @chars = salt.chars.freeze
    end

    attr_reader :salt, :chars
  end
end
