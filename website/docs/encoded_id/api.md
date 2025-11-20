---
layout: default
title: API Reference
parent: EncodedId
nav_order: 2
---

# Reference
{: .no_toc }

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}
 
## EncodedId::ReversibleId

The main class for encoding and decoding IDs.

### Factory Methods

EncodedId provides factory methods to create encoder instances. These are the recommended way to create encoders.

#### `ReversibleId.hashid(**options)`

Creates a Hashid-based encoder. Hashids require a salt for encoding/decoding.

```ruby
# Basic usage with salt
coder = EncodedId::ReversibleId.hashid(salt: "my-salt")

# With custom options
coder = EncodedId::ReversibleId.hashid(
  salt: "my-salt",
  min_length: 8,
  split_at: 4,
  split_with: "-"
)
```

#### `ReversibleId.sqids(**options)`

Creates a Sqids-based encoder (default). Sqids do not require a salt.

```ruby
# Basic usage (uses defaults)
coder = EncodedId::ReversibleId.sqids

# With custom options
coder = EncodedId::ReversibleId.sqids(
  min_length: 8,
  alphabet: EncodedId::Alphabet.modified_crockford,
  split_at: 4
)
```

### Constructor

For advanced use cases, you can use the constructor directly with a configuration object:

```ruby
config = EncodedId::Encoders::HashidConfiguration.new(salt: "my-salt")
coder = EncodedId::ReversibleId.new(config)

# Or use default Sqids configuration
coder = EncodedId::ReversibleId.new
```

### Common Parameters

These parameters are available for both `hashid` and `sqids` factory methods:

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `salt` | `String` | (Required for hashid) | Secret salt for encoding (must be > 3 chars, hashid only) |
| `min_length` | `Integer` | `8` | Minimum length of encoded string |
| `split_at` | `Integer` or `nil` | `4` | Split encoded string every X characters (nil to disable) |
| `split_with` | `String` or `nil` | `"-"` | Character to split with (nil to disable) |
| `alphabet` | `EncodedId::Alphabet` | `EncodedId::Alphabet.modified_crockford` | Custom alphabet for encoding |
| `hex_digit_encoding_group_size` | `Integer` | `4` | For hex encoding (experimental) |
| `max_length` | `Integer` or `nil` | `128` | Maximum length of encoded string (nil for no limit) |
| `max_inputs_per_id` | `Integer` | `32` | Maximum number of IDs to encode |
| `blocklist` | `Array`, `Set`, or `nil` | `nil` | Words to prevent in encoded IDs |

### Methods

#### `#encode(values)`

Encodes one or more integer IDs into an obfuscated string.

```ruby
coder = EncodedId::ReversibleId.hashid(salt: "my-salt")

# Encode a single ID
coder.encode(123)
# => "m3pm-8anj"

# Encode multiple IDs
coder.encode([78, 45])
# => "ny9y-sd7p"
```

**Parameters:**
- `values`: Integer or Array of Integers to encode

**Returns:**
- String containing the encoded ID

**Exceptions:**
- `EncodedId::InvalidInputError`: If negative integers are provided or too many inputs
- `EncodedId::EncodedIdLengthError`: If result exceeds `max_length`

#### `#decode(encoded_id, downcase: false)`

Decodes an encoded string back into the original integer ID(s).

```ruby
coder = EncodedId::ReversibleId.hashid(salt: "my-salt")

# Decode to original IDs
coder.decode("m3pm-8anj")
# => [123]

coder.decode("ny9y-sd7p")
# => [78, 45]

# Resilient to confused characters (with downcase: true)
coder.decode("M3PM-8ANJ", downcase: true)
# => [123]

# Character equivalences work automatically (i mapped to j)
coder.decode("m3pm-8ani")
# => [123]
```

**Parameters:**
- `encoded_id`: String containing the encoded ID
- `downcase`: Boolean, whether to convert the input to lowercase (default: false)

**Returns:**
- Array of integers representing the original IDs

**Exceptions:**
- `EncodedId::EncodedIdFormatError`: If input is invalid or exceeds max length

#### `#encode_hex(hex_strings)` (Experimental)

Encodes one or more hexadecimal strings (e.g., UUIDs) into an obfuscated string.

```ruby
coder = EncodedId::ReversibleId.hashid(salt: "my-salt")

# Encode a UUID (hyphens in input are ignored)
coder.encode_hex("9a566b8b861842ab8db7a5a0276401fd")
# => "q66d-1429-0v59-qug7-35fv-9mys-kx58-ujvr-mfq6-av"
```

See [Hex Encoding Features](index.html#hex-encoding-features-experimental) for UUID encoding examples and optimization options.

**Parameters:**
- `hex_strings`: String or Array of Strings containing hex digits

**Returns:**
- String containing the encoded ID

**Exceptions:**
- `EncodedId::InvalidInputError`: If input is invalid or too many inputs
- `EncodedId::EncodedIdLengthError`: If result exceeds `max_length`

#### `#decode_hex(encoded_id, downcase: false)` (Experimental)

Decodes an encoded string back into the original hexadecimal string(s).

```ruby
coder = EncodedId::ReversibleId.hashid(salt: "my-salt")

# Decode to original hex string
coder.decode_hex("q66d-1429-0v59-qug7-35fv-9mys-kx58-ujvr-mfq6-av")
# => ["9a566b8b861842ab8db7a5a0276401fd"]
```

**Note:** The decoded hex strings do not include hyphens, even if the original UUID had them.

**Parameters:**
- `encoded_id`: String containing the encoded ID
- `downcase`: Boolean, whether to convert the input to lowercase (default: false)

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
coder = EncodedId::ReversibleId.hashid(salt: "my-salt", alphabet: alphabet)
coder.encode(123)
# => "πφλχ-ψησω"

# Custom alphabet with equivalences
alphabet = EncodedId::Alphabet.new("!@#$%^&*()+-={}", {"_" => "-"})
coder = EncodedId::ReversibleId.hashid(salt: "my-salt", alphabet: alphabet)
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