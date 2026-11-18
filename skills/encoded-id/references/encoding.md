# Encoding and decoding

## Building a coder

Use the factory methods. Both accept every option listed in `SKILL.md`.

```ruby
coder = EncodedId::ReversibleId.sqids(min_length: 10, blocklist: EncodedId::Blocklist.minimal)
coder = EncodedId::ReversibleId.hashid(salt: "my-salt", min_length: 10)
coder = EncodedId::ReversibleId.new            # same as ReversibleId.sqids
```

The factories build a configuration object and pass it to `ReversibleId.new`. You can do the same yourself:

```ruby
config = EncodedId::Encoders::SqidsConfiguration.new(min_length: 10)
config = EncodedId::Encoders::HashidConfiguration.new(salt: "my-salt", min_length: 10)
coder = EncodedId::ReversibleId.new(config)

coder.config.min_length   # => 10
```

Configurations validate their options when they are built and raise
`EncodedId::InvalidConfigurationError` (or `EncodedId::InvalidAlphabetError` for the alphabet).
A coder holds no mutable state, so build it once and reuse it, for example in a constant.

### Thread safety

A coder is read-only once built. `encode`, `decode`, `encode_hex` and `decode_hex` may be called on one shared
coder from any number of threads, with no locking, and return the same results as single-threaded use.

```ruby
ENCODER = EncodedId::ReversibleId.sqids(min_length: 10)
ENCODER.decode(ENCODER.encode(42)) # => [42], from any thread
```

Not covered: custom encoders from your own `BaseConfiguration#create_encoder` are only as thread-safe as their own
`encode` and `decode`. The alphabet, blocklist and configuration are frozen and must not be changed in place.

## encode(values)

Takes an integer or an array of integers (at most `max_inputs_per_id`), and returns a string.

```ruby
coder = EncodedId::ReversibleId.sqids
coder.encode(123)         # => "37vq-3u7t"
coder.encode([78, 45])    # => "sy05-kwy3"
coder.encode("12")        # => "ex4w-rmt4" (base-10 integer strings are accepted)
coder.encode(2.0)         # => "1q6t-50yk" (whole floats are accepted)
```

It raises `EncodedId::InvalidInputError` for `nil`, negative numbers, strings that are not base-10 integers,
fractional or non-finite floats, an empty array, more values than `max_inputs_per_id`, and, with Sqids, values
above 2**62 - 1 (4611686018427387903). It raises
`EncodedId::EncodedIdLengthError` if the result is longer than `max_length`.

## decode(encoded_id, downcase: false)

Returns an array of integers, or `[]` when the string is not an ID this coder would issue.

```ruby
coder.decode("37vq-3u7t")     # => [123]
coder.decode("sy05-kwy3")     # => [78, 45]
coder.decode("37vq3u7t")      # => [123] (separators are removed first)
coder.decode("42")            # => []
```

Before decoding, the coder removes `split_with` characters, downcases the input if `downcase: true`, and maps
character equivalences (see `alphabets-and-blocklists.md`). It then decodes and re-encodes the result, and returns
`[]` unless that matches the input. So only the exact string the current settings produce is accepted.

It raises `EncodedId::EncodedIdFormatError` if the input is longer than `max_length` or malformed. Rescue it
around user input:

```ruby
def find_widget_id(param)
  CODER.decode(param).first
rescue EncodedId::EncodedIdFormatError
  nil
end
```

Decoding is case-sensitive. `downcase: true` lower-cases the input first, which suits the default lower-case
alphabet; do not use it with an alphabet that has upper-case letters.

## Lengths and limits

- `min_length` (default 8) pads the hash to at least that many characters, before separators are added. Longer
  values and arrays of values give longer hashes.
- `max_length` (default 128) caps both directions: `encode` raises `EncodedIdLengthError` above it and `decode`
  raises `EncodedIdFormatError` above it, so a long string from a request cannot cost much CPU. `nil` turns the
  limit off. The length counts separators.
- `max_inputs_per_id` (default 32) caps how many integers one ID may hold.

## Grouping

```ruby
EncodedId::ReversibleId.sqids.encode(123)                                  # => "37vq-3u7t"
EncodedId::ReversibleId.sqids(split_at: 3, split_with: ".").encode(123)    # => "37v.q3u.7t"
EncodedId::ReversibleId.sqids(split_at: nil).encode(123)                   # => "37vq3u7t"
```

`split_with` must not be a character of the alphabet. Decoding removes the current `split_with` before decoding, so
changing `split_at` does not invalidate issued IDs. Changing `split_with` does: issued IDs still contain the old
separator, which is no longer removed, so they decode to `[]`.

## Settings that invalidate issued IDs

Changing any of these makes previously issued IDs decode to `[]` (or to other numbers):

- the encoder (Sqids and Hashids are not compatible)
- the salt (Hashids)
- the alphabet
- `min_length`
- the blocklist, `blocklist_mode` or `blocklist_max_length`, for IDs that the new settings would encode differently
- `split_with`, for IDs issued with the old separator
- `downcase` on decode, for an alphabet with upper-case letters

Changing `split_at` or adding character equivalences does not.

## Upgrading from versions before 1.0

1.0 made Sqids the default and decoding case-sensitive. To keep decoding IDs issued by 0.x, build a Hashids coder
with the old salt and options, and decode with `downcase: true`:

```ruby
coder = EncodedId::ReversibleId.hashid(salt: "the-old-salt")
coder.decode(id, downcase: true)
```

The CHANGELOG lists every breaking change: https://github.com/stevegeek/encoded_id/blob/main/CHANGELOG.md
