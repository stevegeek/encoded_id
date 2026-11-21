# Hex strings and UUIDs (experimental)

`encode_hex` and `decode_hex` encode hexadecimal strings, such as UUIDs, the same way `encode` encodes integers.
The API is marked experimental and may change.

```ruby
coder = EncodedId::ReversibleId.sqids

coder.encode_hex("9a566b8b-8618-42ab-8db7-a5a0276401fd")
# => "vex1-w84t-pd6u-zmgq-txjm-bcgg-496x-420a-5wh"

coder.decode_hex("vex1-w84t-pd6u-zmgq-txjm-bcgg-496x-420a-5wh")
# => ["9a566b8b861842ab8db7a5a0276401fd"]

coder.encode_hex(["10f8c", "abc"])   # several hex strings in one ID
coder.decode_hex(coder.encode_hex(["10f8c", "abc"]))   # => ["10f8c", "abc"]
```

- Input may be in either case; output is lower case. Characters that are not hex digits, such as UUID hyphens,
  are removed, so add the hyphens back yourself if you need them.
- Leading zeros and empty strings are kept: `"00ff"` decodes to `"00ff"`, and `["", "ab"]` to `["", "ab"]`.
- A non-empty string with no hex digits raises `EncodedId::InvalidInputError`.
- `decode_hex` has the same contract as `decode`: `[]` for strings this coder would not issue, and
  `EncodedId::EncodedIdFormatError` for input longer than `max_length` or malformed input.

## hex_digit_encoding_group_size

Each hex string is split into groups of this many digits (1 to 12, default 4), and each group becomes one
integer. Larger groups give shorter IDs:

```ruby
uuid = "9a566b8b-8618-42ab-8db7-a5a0276401fd"

EncodedId::ReversibleId.hashid(salt: "my-salt").encode_hex(uuid)
# => "q66d-1429-0v59-qug7-35fv-9mys-kx58-ujvr-mfq6-av"
EncodedId::ReversibleId.hashid(salt: "my-salt", hex_digit_encoding_group_size: 12).encode_hex(uuid)
# => "gdjj-myzm-dk5m-hyg6-e23g-w7kk-1wyg-8472-x"
EncodedId::ReversibleId.sqids(hex_digit_encoding_group_size: 12).encode_hex(uuid)
# => "n33f-m4rs-mkzx-gy61-1ce6-fezs-zkv3-fd"
```

A group size outside 1..12 raises `EncodedId::InvalidConfigurationError` when the coder is built.

Long hex input makes long IDs. `encode_hex` raises `EncodedId::EncodedIdLengthError` when the result is longer than
`max_length` (128 by default); raise `max_length` to fit the longest value you encode.

Never change the group size after IDs are issued: issued IDs still decode, but to different hex strings.
