---
layout: default
title: Reference
parent: EncodedId
nav_order: 3
---

# Reference

## EncodedId::ReversibleId

The main class for encoding and decoding IDs.

### Constructor

```ruby
EncodedId::ReversibleId.new(
  salt:,                         # Required: String salt (must be > 3 chars)
  length: 8,                     # Optional: Minimum length of encoded string
  split_at: 4,                   # Optional: Split encoded string every X characters
  split_with: "-",               # Optional: Character to split with
  alphabet: EncodedId::Alphabet.modified_crockford, # Optional: Custom alphabet
  hex_digit_encoding_group_size: 4, # Optional: For hex encoding (experimental)
  max_length: 128,               # Optional: Maximum length of encoded string
  max_inputs_per_id: 32,         # Optional: Maximum number of IDs to encode
  encoder: :hashids,             # Optional: ID encoding engine (:hashids or :sqids)
  blocklist: nil                 # Optional: Words to prevent in encoded IDs
)
```

#### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `salt` | `String` | (Required) | Secret salt for encoding (must be > 3 chars) |
| `length` | `Integer` | `8` | Minimum length of encoded string |
| `split_at` | `Integer` or `nil` | `4` | Split encoded string every X characters (nil to disable) |
| `split_with` | `String` or `nil` | `"-"` | Character to split with (nil to disable) |
| `alphabet` | `EncodedId::Alphabet` | `EncodedId::Alphabet.modified_crockford` | Custom alphabet for encoding |
| `hex_digit_encoding_group_size` | `Integer` | `4` | For hex encoding (experimental) |
| `max_length` | `Integer` or `nil` | `128` | Maximum length of encoded string (nil for no limit) |
| `max_inputs_per_id` | `Integer` | `32` | Maximum number of IDs to encode |
| `encoder` | `Symbol` | `:hashids` | ID encoding engine (`:hashids` or `:sqids`) |
| `blocklist` | `Array`, `Set`, or `nil` | `nil` | Words to prevent in encoded IDs |

### Methods

#### `#encode(values)`

Encodes one or more integer IDs into an obfuscated string.

```ruby
coder = EncodedId::ReversibleId.new(salt: "my-salt")

# Encode a single ID
coder.encode(123)
# => "p5w9-z27j"

# Encode multiple IDs
coder.encode([78, 45])
# => "z2j7-0dmw"
```

**Parameters:**
- `values`: Integer or Array of Integers to encode

**Returns:**
- String containing the encoded ID

**Exceptions:**
- `EncodedId::InvalidInputError`: If negative integers are provided or too many inputs
- `EncodedId::EncodedIdLengthError`: If result exceeds `max_length`

#### `#decode(encoded_id, downcase: true)`

Decodes an encoded string back into the original integer ID(s).

```ruby
coder = EncodedId::ReversibleId.new(salt: "my-salt")

# Decode to original IDs
coder.decode("p5w9-z27j")
# => [123]

coder.decode("z2j7-0dmw")
# => [78, 45]

# Resilient to confused characters
coder.decode("z2j7-Odmw") # Note the capital 'O' instead of zero
# => [78, 45]
```

**Parameters:**
- `encoded_id`: String containing the encoded ID
- `downcase`: Boolean, whether to convert the input to lowercase (default: true)

**Returns:**
- Array of integers representing the original IDs

**Exceptions:**
- `EncodedId::EncodedIdFormatError`: If input is invalid or exceeds max length

#### `#encode_hex(hex_strings)` (Experimental)

Encodes one or more hexadecimal strings into an obfuscated string.

```ruby
coder = EncodedId::ReversibleId.new(salt: "my-salt")

# Encode a hex string
coder.encode_hex("10f8c")
# => "w72a-y0az"

# Encode a UUID
coder.encode_hex("9a566b8b-8618-42ab-8db7-a5a0276401fd")
# => "5jjy-c8d9-hxp2-qsve-rgh9-rxnt-7nb5-tve7-bf84-vr"

# With larger hex_digit_encoding_group_size for shorter output
coder = EncodedId::ReversibleId.new(
  salt: "my-salt", 
  hex_digit_encoding_group_size: 32
)
coder.encode_hex("9a566b8b-8618-42ab-8db7-a5a0276401fd")
# => "vr7m-qra8-m5y6-dkgj-5rqr-q44e-gp4a-52"
```

**Parameters:**
- `hex_strings`: String or Array of Strings containing hex digits

**Returns:**
- String containing the encoded ID

**Exceptions:**
- `EncodedId::InvalidInputError`: If input is invalid or too many inputs
- `EncodedId::EncodedIdLengthError`: If result exceeds `max_length`

#### `#decode_hex(encoded_id, downcase: true)` (Experimental)

Decodes an encoded string back into the original hexadecimal string(s).

```ruby
coder = EncodedId::ReversibleId.new(salt: "my-salt")

# Decode to original hex string
coder.decode_hex("w72a-y0az")
# => ["10f8c"]

# Decode UUID
coder.decode_hex("5jjy-c8d9-hxp2-qsve-rgh9-rxnt-7nb5-tve7-bf84-vr")
# => ["9a566b8b-8618-42ab-8db7-a5a0276401fd"]
```

**Parameters:**
- `encoded_id`: String containing the encoded ID
- `downcase`: Boolean, whether to convert the input to lowercase (default: true)

**Returns:**
- Array of strings representing the original hex values

**Exceptions:**
- `EncodedId::EncodedIdFormatError`: If input is invalid or exceeds max length

## EncodedId::Alphabet

Class for creating custom alphabets to use with `EncodedId::ReversibleId`.

### Constructor

```ruby
EncodedId::Alphabet.new(characters, equivalences = nil)
```

#### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `characters` | `String` or `Array` | (Required) | Characters to use in the alphabet (minimum 16 unique) |
| `equivalences` | `Hash` or `nil` | `nil` | Mapping of characters to their equivalents |

### Predefined Alphabets

#### `EncodedId::Alphabet.modified_crockford`

Default alphabet used by `EncodedId::ReversibleId`. Based on Crockford's Base32.

```ruby
# Characters: "0123456789abcdefghjkmnpqrstuvwxyz"
# Equivalences: {"o" => "0", "i" => "j", "l" => "1", "O" => "0", "I" => "j", "L" => "1"}
alphabet = EncodedId::Alphabet.modified_crockford
```

### Examples

```ruby
# Custom alphabet with Greek characters
alphabet = EncodedId::Alphabet.new("ςερτυθιοπλκξηγφδσαζχψωβνμ")
coder = EncodedId::ReversibleId.new(salt: "my-salt", alphabet: alphabet)
coder.encode(123)
# => "πφλχ-ψησω"

# Custom alphabet with equivalences
alphabet = EncodedId::Alphabet.new("!@#$%^&*()+-={}", {"_" => "-"})
coder = EncodedId::ReversibleId.new(salt: "my-salt", alphabet: alphabet)
coder.encode(123)
# => "}*^(-^}*="
```

## Exceptions

| Exception | Description |
|-----------|-------------|
| `EncodedId::InvalidConfigurationError` | Invalid configuration (salt, length, etc.) |
| `EncodedId::InvalidAlphabetError` | Invalid alphabet (not enough characters, etc.) |
| `EncodedId::EncodedIdFormatError` | Invalid encoded ID format |
| `EncodedId::EncodedIdLengthError` | Encoded ID exceeds maximum length |
| `EncodedId::InvalidInputError` | Invalid input (negative integers, etc.) |
| `EncodedId::SaltError` | Invalid salt (too short, etc.) |