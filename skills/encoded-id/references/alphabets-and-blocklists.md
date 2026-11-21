# Alphabets and blocklists

## EncodedId::Alphabet

The alphabet is the set of characters a hash may contain. Pass an `EncodedId::Alphabet`, not a string, as the
`alphabet` option.

```ruby
EncodedId::Alphabet.modified_crockford   # default: "0123456789abcdefghjkmnpqrstuvwxyz" (33 characters)
EncodedId::Alphabet.alphanum             # a-z, A-Z and 0-9 (62 characters)

hex = EncodedId::Alphabet.new("0123456789ABCDEF")
EncodedId::ReversibleId.sqids(alphabet: hex).encode(123)   # => "EB61-5697"
```

`Alphabet.new(characters, equivalences = nil)` takes a string or an array of single characters. Duplicates are
dropped. It raises `EncodedId::InvalidAlphabetError` for an empty alphabet or one with whitespace or null
characters. Size limits depend on the encoder and are checked when the coder is built: Sqids needs 3 or more unique
characters (`EncodedId::Encoders::Sqids::MIN_ALPHABET_SIZE`), Hashids 16 or more
(`EncodedId::Encoders::Hashid::MIN_ALPHABET_SIZE`). `EncodedId::Alphabet::MIN_UNIQUE_CHARACTERS` is deprecated.

Sqids rejects alphabets with multibyte characters when the coder is built; Hashids accepts them.

The group separator (`split_with`, `-` by default) must not be in the alphabet.

### Character equivalences

Equivalences map characters a person may type by mistake to characters of the alphabet. They are applied to the
input of `decode` before decoding. The default alphabet maps `o` to `0`, `i` to `j` and `l` to `1`, and leaves
out `i`, `l`, `o` and `u`.

```ruby
coder = EncodedId::ReversibleId.sqids
coder.encode(1)              # => "dchf-51kr"
coder.decode("dchf-5lkr")    # => [1] ("l" is read as "1")
```

For a custom alphabet, pass a hash of single characters. Keys must not be in the alphabet and values must be:

```ruby
alphabet = EncodedId::Alphabet.new(
  "0123456789ABCDEF",
  {"a" => "A", "b" => "B", "c" => "C", "d" => "D", "e" => "E", "f" => "F"}
)
coder = EncodedId::ReversibleId.sqids(alphabet: alphabet)
coder.encode(123)              # => "EB61-5697"
coder.decode("eb61-5697")      # => [123]
```

An invalid equivalence hash raises `EncodedId::InvalidConfigurationError`.

### Separating coders with Sqids

Sqids has no salt, so two coders with the same options encode a number to the same string. To give a second set of
IDs different strings, give it a different alphabet, for example a fixed shuffle of the default characters. A hash
from one coder then never decodes to the same number through the other, but it can occasionally decode to a
different number, so do not rely on this to scope access.

## EncodedId::Blocklist

A blocklist stops the coder from issuing hashes that contain given words.

```ruby
EncodedId::Blocklist.empty             # default
EncodedId::Blocklist.minimal           # 51 common English profanities
EncodedId::Blocklist.sqids_blocklist   # the Sqids project's list (560 words)

custom = EncodedId::Blocklist.new(["word", "other"])          # or pass an Array or Set as `blocklist:`
combined = EncodedId::Blocklist.minimal.merge(custom)

combined.include?("WORD")              # => true (words are lower-cased)
combined.blocks?("xxwordxx")           # => "word" (the matched word, or false)
```

When a coder is built, the blocklist is filtered to words of 3 or more characters that can be written with the
alphabet. Words are lower-cased, so a blocklist has no effect with an alphabet that has only upper-case letters.

How each encoder uses it:

- **Sqids** re-encodes with a shifted alphabet until the hash contains no blocked word. Encoding gets slower with a
  large blocklist, and the result differs from the hash without the blocklist:

  ```ruby
  EncodedId::ReversibleId.sqids.encode(123)                        # => "37vq-3u7t"
  EncodedId::ReversibleId.sqids(blocklist: ["37vq"]).encode(123)   # => "85m3-akp9"
  ```

- **Hashids** raises `EncodedId::BlocklistError` when the hash contains a blocked word. Handle it where you encode,
  for example by reporting it; it cannot pick another hash for the same number.

### Blocklist modes

Long hashes contain blocked words often, which makes Sqids loop and Hashids raise. `blocklist_mode` limits this:

| Mode | Behaviour |
|---|---|
| `:length_threshold` (default) | Check only hashes up to `blocklist_max_length` characters (default 32) |
| `:always` | Check every hash, whatever its length |
| `:raise_if_likely` | Check every hash, and raise `InvalidConfigurationError` when the coder is built if `min_length` is above `blocklist_max_length` or `max_inputs_per_id` is above 100 |

```ruby
EncodedId::ReversibleId.sqids(
  blocklist: EncodedId::Blocklist.minimal,
  blocklist_mode: :length_threshold,
  blocklist_max_length: 32
)
```

Changing the blocklist or its mode after IDs are issued invalidates the issued IDs that the new settings encode
differently.
