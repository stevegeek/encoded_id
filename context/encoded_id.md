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
- **Blocklist Modes**: Three modes for controlling blocklist checking performance

## Quick Reference

```ruby
# Sqids encoder (default, no salt required)
coder = EncodedId::ReversibleId.sqids(min_length: 10)
id = coder.encode(123)          # => "p5w9-z27j-k8"
nums = coder.decode(id)         # => [123]

# Hashids encoder (requires salt)
coder = EncodedId::ReversibleId.hashid(salt: "my-salt", min_length: 8)
id = coder.encode([78, 45])     # => "z2j7-0dmw"
nums = coder.decode(id)         # => [78, 45]

# UUID encoding (experimental)
hex_id = coder.encode_hex("9a566b8b-8618-42ab-8db7-a5a0276401fd")
uuid = coder.decode_hex(hex_id).first
```

## Core API

### EncodedId::ReversibleId

The main class for encoding and decoding IDs.

#### Factory Methods (Recommended)

Factory methods provide the cleanest way to create encoders:

```ruby
# Sqids encoder (default, no salt required)
coder = EncodedId::ReversibleId.sqids(
  min_length: 10,
  blocklist: ["bad", "words"]
)

# Hashids encoder (requires salt)
coder = EncodedId::ReversibleId.hashid(
  salt: "my-salt",
  min_length: 8,
  blocklist: ["bad", "words"]
)
```

Both factory methods accept all configuration options described below.

#### Constructor (Alternative)

You can also use the constructor with explicit configuration objects:

```ruby
# Using Sqids configuration
config = EncodedId::Encoders::SqidsConfiguration.new(
  min_length: 8,                 # Minimum length of encoded string
  split_at: 4,                   # Split encoded string every X characters
  split_with: "-",               # Character to split with
  alphabet: EncodedId::Alphabet.modified_crockford,
  hex_digit_encoding_group_size: 4,
  max_length: 128,               # Maximum length limit
  max_inputs_per_id: 32,         # Maximum IDs to encode together
  blocklist: nil,                # Words to prevent in IDs
  blocklist_mode: :length_threshold,  # :always, :length_threshold, or :raise_if_likely
  blocklist_max_length: 32       # Max length for :length_threshold mode
)
coder = EncodedId::ReversibleId.new(config)

# Using Hashids configuration (requires salt)
config = EncodedId::Encoders::HashidConfiguration.new(
  salt: "my-salt",               # Required for Hashids (min 4 chars)
  min_length: 8,
  # ... other options same as above
)
coder = EncodedId::ReversibleId.new(config)
```

**Note**: As of v1.0.0, the default encoder is `:sqids`. For backwards compatibility with pre-v1 versions, use `ReversibleId.hashid()`.

#### Key Methods

##### encode(values)
Encodes one or more integer IDs into an obfuscated string.

```ruby
coder = EncodedId::ReversibleId.sqids

# Single ID
coder.encode(123) # => "p5w9-z27j"

# Multiple IDs
coder.encode([78, 45]) # => "z2j7-0dmw"
```

##### decode(encoded_id, downcase: false)
Decodes an encoded string back to original IDs.

```ruby
coder.decode("p5w9-z27j") # => [123]
coder.decode("z2j7-0dmw") # => [78, 45]

# Case-sensitive by default (v1.0.0+)
coder.decode("p5w9-z27J") # => [] (case doesn't match)

# For case-insensitive matching (pre-v1 behavior)
coder.decode("p5w9-z27J", downcase: true) # => [123]
```

**Note**: As of v1.0.0, decoding is case-sensitive by default (`downcase: false`). Set `downcase: true` for backwards compatibility.

##### encode_hex(hex_strings) (Experimental)
Encodes hexadecimal strings (like UUIDs).

```ruby
# Encode UUID
coder.encode_hex("9a566b8b-8618-42ab-8db7-a5a0276401fd")
# => "5jjy-c8d9-hxp2-qsve-rgh9-rxnt-7nb5-tve7-bf84-vr"

# With larger group size for shorter output
coder = EncodedId::ReversibleId.sqids(hex_digit_encoding_group_size: 32)
coder.encode_hex("9a566b8b-8618-42ab-8db7-a5a0276401fd")
# => "vr7m-qra8-m5y6-dkgj-5rqr-q44e-gp4a-52"
```

##### decode_hex(encoded_id, downcase: false) (Experimental)
Decodes back to hexadecimal strings.

```ruby
coder.decode_hex("w72a-y0az") # => ["10f8c"]

# For case-insensitive decoding (pre-v1 behavior)
coder.decode_hex("W72A-Y0AZ", downcase: true) # => ["10f8c"]
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
coder = EncodedId::ReversibleId.sqids(alphabet: alphabet)
coder.encode(123) # => "θεαψ-ζκυο"
```

### EncodedId::Blocklist

Class for managing profanity/word blocklists.

#### Predefined Blocklists

```ruby
# Empty blocklist (no filtering)
EncodedId::Blocklist.empty

# Minimal blocklist (~50 common profane words)
EncodedId::Blocklist.minimal

# Full Sqids default blocklist (comprehensive)
EncodedId::Blocklist.sqids_blocklist

# Use in configuration
coder = EncodedId::ReversibleId.sqids(
  blocklist: EncodedId::Blocklist.minimal
)
```

#### Custom Blocklists

```ruby
# From array
blocklist = EncodedId::Blocklist.new(["bad", "offensive", "words"])

# Merge blocklists
combined = EncodedId::Blocklist.minimal.merge(
  EncodedId::Blocklist.new(["custom", "words"])
)

# Filter for specific alphabet (automatic with configuration)
filtered = blocklist.filter_for_alphabet(EncodedId::Alphabet.modified_crockford)
```

**Note**: Blocklists are automatically filtered to only include words possible with your configured alphabet. This optimization improves performance.

## Configuration Options

### Basic Options

- **min_length**: Minimum length of encoded string (default: 8)
- **max_length**: Maximum allowed length (default: 128) to prevent DoS attacks
- **max_inputs_per_id**: Maximum IDs encodable together (default: 32)
- **hex_digit_encoding_group_size**: Group size for hex encoding (default: 4)

### Encoder Selection

```ruby
# Sqids encoder (default, no salt required)
coder = EncodedId::ReversibleId.sqids

# Hashids encoder (requires salt - minimum 4 characters)
coder = EncodedId::ReversibleId.hashid(salt: "my-salt-minimum-4-chars")
```

**Important**:
- As of v1.0.0, `:sqids` is the default encoder
- **Sqids**: No salt required, automatically avoids blocklisted words via iteration
- **Hashids**: Salt required (min 4 chars), raises exception if blocklisted word appears
- HashIds and Sqids produce different encodings and are **not compatible**
- Do NOT change encoders after going to production with existing encoded IDs

### Blocklist Configuration

#### Blocklist Modes

Control how blocklist checking behaves to balance performance and safety:

```ruby
# :length_threshold (default) - Check blocklist only until encoded length reaches blocklist_max_length
# Best for most use cases - prevents performance issues with very long IDs
coder = EncodedId::ReversibleId.sqids(
  blocklist: EncodedId::Blocklist.minimal,
  blocklist_mode: :length_threshold,
  blocklist_max_length: 32  # Stop checking after 32 characters
)

# :always - Always check blocklist regardless of encoded length
# Can be slow for long IDs or large blocklists
coder = EncodedId::ReversibleId.hashid(
  salt: "my-salt",
  blocklist: ["bad", "words"],
  blocklist_mode: :always
)

# :raise_if_likely - Raise error at configuration time if settings likely cause blocklist collisions
# Prevents configurations that would cause performance issues
coder = EncodedId::ReversibleId.sqids(
  min_length: 8,
  blocklist: ["bad", "words"],
  blocklist_mode: :raise_if_likely
)
# Raises InvalidConfigurationError if min_length > blocklist_max_length
```

**Blocklist Behavior by Encoder**:
- **Sqids**: Iteratively regenerates to avoid blocklisted words (may impact encoding performance)
- **Hashids**: Raises `EncodedId::BlocklistError` if a blocklisted word appears

**Recommendation**: Use `:length_threshold` mode (default) for best balance of performance and safety.

### Formatting Options

```ruby
# Custom splitting
coder = EncodedId::ReversibleId.sqids(
  split_at: 3,      # Group every 3 chars
  split_with: "."   # Use dots
)
coder.encode(123) # => "p5w.9z2.7j"

# No splitting
coder = EncodedId::ReversibleId.sqids(split_at: nil)
coder.encode(123) # => "p5w9z27j"
```

## Exception Handling

| Exception | Description |
|-----------|-------------|
| `EncodedId::InvalidConfigurationError` | Invalid configuration parameters |
| `EncodedId::InvalidAlphabetError` | Invalid alphabet (< 16 unique chars) |
| `EncodedId::EncodedIdFormatError` | Invalid encoded ID format |
| `EncodedId::EncodedIdLengthError` | Encoded ID exceeds max_length |
| `EncodedId::InvalidInputError` | Invalid input (negative integers, too many inputs) |
| `EncodedId::SaltError` | Invalid salt (too short, only for Hashids) |
| `EncodedId::BlocklistError` | Generated ID contains blocklisted word (Hashids only) |

## Usage Examples

### Basic Usage
```ruby
# Initialize with Sqids (no salt needed)
coder = EncodedId::ReversibleId.sqids

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

### With Hashids and Blocklist
```ruby
coder = EncodedId::ReversibleId.hashid(
  salt: "my-app-salt",
  min_length: 12,
  blocklist: EncodedId::Blocklist.minimal,
  blocklist_mode: :length_threshold
)

encoded = coder.encode(123)
# Raises BlocklistError if result contains blocklisted word
```

### Custom Configuration
```ruby
# Highly customized Sqids instance
coder = EncodedId::ReversibleId.sqids(
  min_length: 12,
  split_at: 3,
  split_with: ".",
  alphabet: EncodedId::Alphabet.new("0123456789ABCDEF"),
  blocklist: ["BAD", "FAKE"],
  blocklist_mode: :length_threshold,
  blocklist_max_length: 32
)
```

### Hex Encoding (UUIDs)
```ruby
# For encoding UUIDs efficiently
coder = EncodedId::ReversibleId.sqids(hex_digit_encoding_group_size: 32)

uuid = "550e8400-e29b-41d4-a716-446655440000"
encoded = coder.encode_hex(uuid)
decoded = coder.decode_hex(encoded).first # => original UUID (without hyphens)
```

## Performance Considerations

1. **Algorithm Choice**:
   - HashIds: Faster encoding, especially with blocklists
   - Sqids: Faster decoding, automatically avoids blocklisted words

2. **Blocklist Impact**:
   - Large blocklists slow encoding, especially with Sqids (which iterates to avoid words)
   - Hashids may raise exceptions requiring retry logic
   - Use `blocklist_mode: :length_threshold` for best performance
   - `:always` mode can significantly impact encoding speed for long IDs
   - Blocklists are automatically filtered for your alphabet, improving performance

3. **Blocklist Mode Performance**:
   - `:length_threshold` (default): Only checks blocklist for IDs ≤ `blocklist_max_length` (default: 32)
   - `:always`: Checks all IDs regardless of length (can be slow)
   - `:raise_if_likely`: Validates configuration at initialization to prevent performance issues

4. **Length vs Performance**: Longer minimum lengths may require more computation

5. **Memory Usage**: The gem uses optimized implementations to minimize memory allocation

## Version Compatibility

**v1.0.0 Breaking Changes:**

1. **Default encoder**: Changed from `:hashids` to `:sqids`
2. **Case sensitivity**: `decode` is now case-sensitive by default (`downcase: false`)
   - Pre-v1: `decode("ABC")` and `decode("abc")` were equivalent
   - v1.0.0+: These produce different results unless `downcase: true`
3. **Salt requirement**: Sqids (default) doesn't require salt; Hashids still requires salt
4. **Migration**: For backwards compatibility with pre-v1:
   ```ruby
   coder = EncodedId::ReversibleId.hashid(salt: "your-salt")
   decoded = coder.decode(id, downcase: true)
   ```

## Security Notes

**Important**: Encoded IDs are NOT cryptographically secure. They provide obfuscation, not encryption. Do not rely on them for security purposes. They can potentially be reversed through brute-force attacks if the salt is compromised.

Use encoded IDs for:
- Hiding sequential database IDs
- Creating user-friendly URLs
- Preventing ID enumeration attacks
- Obscuring business metrics (user counts, order volumes)

Do NOT use for:
- Secure tokens
- Authentication
- Sensitive data protection
- Cryptographic purposes

## Installation

```ruby
# Gemfile
gem 'encoded_id'
```

## Best Practices

1. **Consistent Configuration**: Once in production, don't change salt, encoder, or alphabet
2. **Error Handling**: Always handle potential exceptions when decoding user input
3. **Length Limits**: Set appropriate max_length to prevent DoS attacks
4. **Validation**: Validate decoded IDs before using them in database queries
5. **Blocklist Mode**: Use `:length_threshold` (default) for production - best performance/safety balance
6. **Factory Methods**: Prefer `ReversibleId.sqids()` and `ReversibleId.hashid()` over constructor
