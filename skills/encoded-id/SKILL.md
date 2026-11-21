---
name: encoded-id
description: "Use when encoding or decoding IDs with the encoded_id gem in Ruby (EncodedId::ReversibleId): choosing between Sqids and Hashids, configuring alphabets, blocklists, lengths and grouping, encoding hex strings or UUIDs, or handling its errors. For ActiveRecord models, use the encoded-id-rails skill."
---

# encoded_id

`encoded_id` turns integers (and hex strings) into short, reversible, URL-safe strings, and back.
It obfuscates IDs; it does not encrypt them. Never use an encoded ID as a secret or an access check.

## Quick reference

```ruby
require "encoded_id"

coder = EncodedId::ReversibleId.sqids          # default encoder, no salt
coder.encode(123)                              # => "37vq-3u7t"
coder.encode([78, 45])                         # => "sy05-kwy3"
coder.decode("37vq-3u7t")                      # => [123]
coder.decode("not-an-id")                      # => []

coder = EncodedId::ReversibleId.hashid(salt: "my-salt")   # salt of 4+ characters
coder.encode(123)                              # => "m3pm-8anj"
coder.decode("m3pm-8anj")                      # => [123]
```

`decode` always returns an array. Take `.first` for a single ID, and treat `[]` as "not a valid ID".

Both factory methods take the same options (defaults shown):

| Option | Default | Meaning |
|---|---|---|
| `min_length` | `8` | Minimum length of the hash, before separators are added |
| `alphabet` | `Alphabet.modified_crockford` | Characters used in the hash |
| `split_at` / `split_with` | `4` / `"-"` | Group the output; `nil` turns grouping off |
| `max_length` | `128` | Longest input `decode` accepts and longest output `encode` returns; `nil` for no limit |
| `max_inputs_per_id` | `32` | Most integers one encoded ID may hold |
| `blocklist` | `Blocklist.empty` | Words that must not appear in a hash |
| `blocklist_mode` | `:length_threshold` | `:length_threshold`, `:always` or `:raise_if_likely` |
| `blocklist_max_length` | `32` | Length up to which `:length_threshold` checks the blocklist |
| `hex_encoding` | `:tagged` | Hex encoding scheme of `encode_hex` and `decode_hex`: `:tagged` or `:legacy` |
| `hex_digit_encoding_group_size` | `4` | Hex digits packed into each integer by `:legacy` `encode_hex`, 1 to 12 |

## Choosing an encoder

- **Sqids** (`ReversibleId.sqids`, also `ReversibleId.new` with no arguments): the default and the choice for new
  projects. No salt. Avoids blocklisted words by re-encoding. Accepts alphabets of 3+ unique characters.
- **Hashids** (`ReversibleId.hashid(salt:)`): for existing IDs issued with Hashids. The Hashids project is deprecated.
  Needs a salt and an alphabet of 16+ unique characters. Raises `EncodedId::BlocklistError` when a hash contains a
  blocklisted word instead of avoiding it.

The two encoders give different strings for the same input and cannot decode each other's IDs. Never switch
encoder once IDs are public.

## Common mistakes

- **Changing settings after IDs are issued.** Both encoders only accept the exact string they would produce today.
  A new encoder, salt, alphabet, `min_length`, blocklist or `split_with` makes existing IDs decode to `[]`.
  A new `split_at` does not.
- **Expecting a salt to vary Sqids output.** Sqids has no salt. Two Sqids coders with the same options give the
  same hash for the same number. Use a different alphabet (for example a shuffled one) to separate them.
- **Upper-case input.** Decoding is case-sensitive. Pass `downcase: true` to `decode` only if the alphabet has no
  upper-case letters.
- **Unvalidated input to `encode`.** It raises `EncodedId::InvalidInputError` for `nil`, negative numbers,
  non-integer strings, fractional floats, empty arrays, more than `max_inputs_per_id` values and, with Sqids,
  values above 2**62 - 1.
- **Long user input to `decode`.** Input longer than `max_length` raises `EncodedId::EncodedIdFormatError`; rescue
  it, or check the length, where the string comes from a request.
- **Non-ASCII alphabets with Sqids.** Sqids rejects multibyte characters when the coder is built; use Hashids, or
  an ASCII alphabet.
- **Building a coder per call.** Construction shuffles the alphabet and filters the blocklist. A coder is
  read-only once built, so build it once (a constant or an initializer) and share it across threads.
- **Treating an encoded ID as a secret.** It is reversible by design. Check authorization on every lookup.

## References

Read the one that matches the task:

- [references/encoding.md](references/encoding.md): `encode`, `decode`, `downcase`, multiple IDs, grouping,
  lengths and limits, configuration objects.
- [references/alphabets-and-blocklists.md](references/alphabets-and-blocklists.md): `EncodedId::Alphabet`,
  character equivalences, `EncodedId::Blocklist`, blocklist modes and their cost.
- [references/hex-and-uuids.md](references/hex-and-uuids.md): `encode_hex` and `decode_hex` (experimental).
- [references/errors.md](references/errors.md): the exception classes and when each is raised.

Full documentation: https://encoded-id.onrender.com/docs/encoded_id/
