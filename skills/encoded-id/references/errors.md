# Errors

All exceptions are defined in the `EncodedId` module.

| Exception | Superclass | Raised when |
|---|---|---|
| `InvalidConfigurationError` | `StandardError` | A configuration option is invalid: a Hashids salt shorter than 4 characters, a `split_with` in the alphabet, a bad blocklist or blocklist mode, invalid character equivalences, a `hex_digit_encoding_group_size` outside 1..12, or `:raise_if_likely` rejecting the settings |
| `InvalidAlphabetError` | `ArgumentError` | The alphabet is not an `EncodedId::Alphabet`, is empty, contains whitespace or null characters, or is too small for the encoder (Sqids 3, Hashids 16) |
| `InvalidInputError` | `ArgumentError` | `encode` gets `nil`, a negative number, a non-integer string, a fractional float, an empty array, too many values or, with Sqids, a value above 2**62 - 1; `encode_hex` gets a non-empty string with no hex digits; also raised when the coder is built if Sqids rejects the alphabet (for example multibyte characters) |
| `EncodedIdLengthError` | `ArgumentError` | `encode` or `encode_hex` produces a string longer than `max_length` |
| `EncodedIdFormatError` | `ArgumentError` | `decode` or `decode_hex` gets input longer than `max_length`, or input the encoder cannot parse |
| `BlocklistError` | `StandardError` | Hashids produced a hash that contains a blocked word |
| `SaltError` | `ArgumentError` | Raised inside the Hashids encoder for an unusable salt; salts given to `ReversibleId.hashid` are checked first and raise `InvalidConfigurationError` |

Configuration errors are raised when the coder is built, so build coders at boot (for example in a constant or an
initializer) to find them early.

An ID that is well formed but was not issued by the coder is not an error: `decode` returns `[]`.

Handling user input:

```ruby
ids = begin
  coder.decode(params[:id])
rescue EncodedId::EncodedIdFormatError
  []
end
return head(:not_found) if ids.empty?
```
