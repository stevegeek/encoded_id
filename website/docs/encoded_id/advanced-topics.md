---
layout: default
title: Advanced Topics
parent: EncodedId
nav_order: 4
---

# Advanced Topics
{: .no_toc }

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

## Performance Considerations

In general, at the moment, Sqids are slower to encode than Hashids (especially if using the blocklist feature). However, they are faster to decode than Hashids. With YJIT enabled, the differences in speeds are smaller.

To get the most out of Sqids encode performance, consider a small (or no) blocklist (set the `blocklist:` option). The default Sqids blocklist is very costly on encode time, but extensive.

## Security Considerations

It's important to understand the security implications of using encoded IDs.

### Not for Sensitive Data

**Encoded IDs are not secure**. They are meant to be used for obfuscation, not encryption. It may be possible to reverse them via brute-force, especially for simple or sequential IDs.

Don't use encoded IDs as the sole protection for sensitive resources. Always implement proper authorization checks.

Read more about the security implications: [Hashids expose salt value](https://www.sjoerdlangkemper.nl/2023/11/25/hashids-expose-salt-value/)

## Salts

**Changing the salt**: If you change your salt, all previously encoded IDs will no longer decode correctly. Have a migration plan if you need to change the salt.

## Hex Encoding Features (Experimental) {#hex-encoding-features-experimental}

EncodedId includes experimental support for encoding hex strings, which can be useful for UUIDs and other hex-based identifiers.

### Encoding UUIDs

```ruby
coder = EncodedId::ReversibleId.new(salt: "my-salt")

# Encode a UUID
uuid = "9a566b8b-8618-42ab-8db7-a5a0276401fd"
encoded = coder.encode_hex(uuid)
# => "5jjy-c8d9-hxp2-qsve-rgh9-rxnt-7nb5-tve7-bf84-vr"

# Decode back to UUID
decoded = coder.decode_hex(encoded)
# => ["9a566b8b-8618-42ab-8db7-a5a0276401fd"]
```

### Optimizing Hex Encoding Length

For long hex strings like UUIDs, you can customize the `hex_digit_encoding_group_size` to get shorter encoded strings:

```ruby
# Default hex_digit_encoding_group_size (4)
coder = EncodedId::ReversibleId.new(salt: "my-salt")
encoded = coder.encode_hex("9a566b8b-8618-42ab-8db7-a5a0276401fd")
# => "5jjy-c8d9-hxp2-qsve-rgh9-rxnt-7nb5-tve7-bf84-vr"

# Larger group size for shorter output
coder = EncodedId::ReversibleId.new(
  salt: "my-salt",
  hex_digit_encoding_group_size: 32
)
encoded = coder.encode_hex("9a566b8b-8618-42ab-8db7-a5a0276401fd")
# => "vr7m-qra8-m5y6-dkgj-5rqr-q44e-gp4a-52"
```
