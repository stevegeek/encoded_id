# EncodedId Ruby Gem - Technical Documentation

## Overview

`encoded_id` is a Ruby gem that provides reversible obfuscation of numerical and hexadecimal IDs into human-readable strings suitable for use in URLs. It offers a secure way to hide sequential database IDs from users while maintaining the ability to decode them back to their original values.

## Key Features

- **Reversible Encoding**: Unlike UUIDs, encoded IDs can be decoded back to their original numeric values
- **Multiple ID Support**: Encode multiple numeric IDs in a single string
- **Algorithm Choice**: Supports both HashIds and Sqids encoding algorithms
- **Human-Readable Format**: Character grouping and configurable separators for better readability
- **Character Mapping**: Handles easily confused characters (0/O, 1/I/l) through equivalence mapping
- **Performance Optimized**: Uses an optimized HashIds implementation for better performance
- **Profanity Protection**: Built-in blocklist support to prevent offensive words in generated IDs
- **Customizable**: Configurable alphabets, lengths, and formatting options

## Core API

### EncodedId::ReversibleId

The main class for encoding and decoding IDs.

#### Constructor

```ruby
EncodedId::ReversibleId.new(
  salt:,                         # Required: String salt (min 4 chars)
  length: 8,                     # Minimum length of encoded string
  split_at: 4,                   # Split encoded string every X characters
  split_with: "-",               # Character to split with
  alphabet: EncodedId::Alphabet.modified_crockford,
  hex_digit_encoding_group_size: 4,
  max_length: 128,               # Maximum length limit
  max_inputs_per_id: 32,         # Maximum IDs to encode together
  encoder: :hashids,             # :hashids or :sqids
  blocklist: nil                 # Words to prevent in IDs
)
```

#### Key Methods

##### encode(values)
Encodes one or more integer IDs into an obfuscated string.

```ruby
coder = EncodedId::ReversibleId.new(salt: "my-salt")

# Single ID
coder.encode(123) # => "p5w9-z27j"

# Multiple IDs
coder.encode([78, 45]) # => "z2j7-0dmw"
```

##### decode(encoded_id, downcase: true)
Decodes an encoded string back to original IDs.

```ruby
coder.decode("p5w9-z27j") # => [123]
coder.decode("z2j7-0dmw") # => [78, 45]

# Handles confused characters
coder.decode("p5w9-z27J") # => [123]
```

##### encode_hex(hex_strings) (Experimental)
Encodes hexadecimal strings (like UUIDs).

```ruby
# Encode UUID
coder.encode_hex("9a566b8b-8618-42ab-8db7-a5a0276401fd")
# => "5jjy-c8d9-hxp2-qsve-rgh9-rxnt-7nb5-tve7-bf84-vr"

# With larger group size for shorter output
coder = EncodedId::ReversibleId.new(
  salt: "my-salt", 
  hex_digit_encoding_group_size: 32
)
coder.encode_hex("9a566b8b-8618-42ab-8db7-a5a0276401fd")
# => "vr7m-qra8-m5y6-dkgj-5rqr-q44e-gp4a-52"
```

##### decode_hex(encoded_id, downcase: true) (Experimental)
Decodes back to hexadecimal strings.

```ruby
coder.decode_hex("w72a-y0az") # => ["10f8c"]
```

### EncodedId::Alphabet

Class for creating custom alphabets.

#### Predefined Alphabets

```ruby
# Default: modified Crockford Base32
# Characters: "0123456789abcdefghjkmnpqrstuvwxyz"
# Excludes: i, l, o, u (easily confused)
# Equivalences: {"o"=>"0", "i"=>"j", "l"=>"1", ...}
EncodedId::Alphabet.modified_crockford
```

#### Custom Alphabets

```ruby
# Simple custom alphabet
alphabet = EncodedId::Alphabet.new("0123456789abcdef")

# With character equivalences
alphabet = EncodedId::Alphabet.new(
  "0123456789ABCDEF",
  {"a"=>"A", "b"=>"B", "c"=>"C", "d"=>"D", "e"=>"E", "f"=>"F"}
)

# Greek alphabet example
alphabet = EncodedId::Alphabet.new("αβγδεζηθικλμνξοπρστυφχψω")
coder = EncodedId::ReversibleId.new(salt: "my-salt", alphabet: alphabet)
coder.encode(123) # => "θεαψ-ζκυο"
```

## Configuration Options

### Basic Options

- **salt**: Required secret salt (minimum 4 characters). Changing the salt changes all encoded IDs
- **length**: Minimum length of encoded string (default: 8)
- **max_length**: Maximum allowed length (default: 128) to prevent DoS attacks
- **max_inputs_per_id**: Maximum IDs encodable together (default: 32)

### Encoder Selection

```ruby
# Default HashIds encoder
coder = EncodedId::ReversibleId.new(salt: "my-salt")

# Sqids encoder (requires 'sqids' gem)
coder = EncodedId::ReversibleId.new(salt: "my-salt", encoder: :sqids)
```

**Important**: HashIds and Sqids produce different encodings and are not compatible.

### Formatting Options

```ruby
# Custom splitting
coder = EncodedId::ReversibleId.new(
  salt: "my-salt",
  split_at: 3,      # Group every 3 chars
  split_with: "."   # Use dots
)
coder.encode(123) # => "p5w.9z2.7j"

# No splitting
coder = EncodedId::ReversibleId.new(
  salt: "my-salt",
  split_at: nil
)
coder.encode(123) # => "p5w9z27j"
```

### Blocklist Configuration

```ruby
# Prevent specific words
coder = EncodedId::ReversibleId.new(
  salt: "my-salt",
  blocklist: ["bad", "offensive", "words"]
)

# Behavior differs by encoder:
# - HashIds: Raises error if blocklisted word appears
# - Sqids: Automatically avoids generating blocklisted words
```

## Exception Handling

| Exception | Description |
|-----------|-------------|
| `EncodedId::InvalidConfigurationError` | Invalid configuration parameters |
| `EncodedId::InvalidAlphabetError` | Invalid alphabet (< 16 unique chars) |
| `EncodedId::EncodedIdFormatError` | Invalid encoded ID format |
| `EncodedId::EncodedIdLengthError` | Encoded ID exceeds max_length |
| `EncodedId::InvalidInputError` | Invalid input (negative integers, too many inputs) |
| `EncodedId::SaltError` | Invalid salt (too short) |

## Usage Examples

### Basic Usage
```ruby
# Initialize
coder = EncodedId::ReversibleId.new(salt: "my-secret-salt")

# Encode/decode cycle
encoded = coder.encode(123)        # => "p5w9-z27j"
decoded = coder.decode(encoded)    # => [123]
original_id = decoded.first        # => 123
```

### Multiple IDs
```ruby
# Encode multiple IDs in one string
encoded = coder.encode([78, 45, 92])  # => "z2j7-0dmw-kf8p"
decoded = coder.decode(encoded)        # => [78, 45, 92]
```

### Custom Configuration
```ruby
# Highly customized instance
coder = EncodedId::ReversibleId.new(
  salt: "my-app-salt",
  encoder: :sqids,
  length: 12,
  split_at: 3,
  split_with: ".",
  alphabet: EncodedId::Alphabet.new("0123456789ABCDEF"),
  blocklist: ["BAD", "FAKE"]
)
```

### Hex Encoding (UUIDs)
```ruby
# For encoding UUIDs efficiently
coder = EncodedId::ReversibleId.new(
  salt: "my-salt",
  hex_digit_encoding_group_size: 32
)

uuid = "550e8400-e29b-41d4-a716-446655440000"
encoded = coder.encode_hex(uuid)
decoded = coder.decode_hex(encoded).first # => original UUID
```

## Performance Considerations

1. **Algorithm Choice**: 
   - HashIds: Faster encoding, especially with blocklists
   - Sqids: Faster decoding

2. **Blocklist Impact**: Large blocklists can slow down encoding, especially with Sqids

3. **Length vs Performance**: Longer minimum lengths may require more computation

4. **Memory Usage**: The gem uses optimized implementations to minimize memory allocation

## Security Notes

**Important**: Encoded IDs are NOT cryptographically secure. They provide obfuscation, not encryption. Do not rely on them for security purposes. They can potentially be reversed through brute-force attacks if the salt is compromised.

Use encoded IDs for:
- Hiding sequential database IDs
- Creating user-friendly URLs
- Preventing ID enumeration attacks

Do NOT use for:
- Secure tokens
- Authentication
- Sensitive data protection

## Installation

```ruby
# Gemfile
gem 'encoded_id'

# Or install directly
gem install encoded_id
```

For Sqids support:
```ruby
gem 'encoded_id'
gem 'sqids'
```

## Best Practices

1. **Salt Management**: Use a strong, unique salt and store it securely (e.g., environment variables)
2. **Consistent Configuration**: Once in production, don't change salt or encoder
3. **Error Handling**: Always handle potential exceptions when decoding user input
4. **Length Limits**: Set appropriate max_length to prevent DoS attacks
5. **Validation**: Validate decoded IDs before using them in database queries