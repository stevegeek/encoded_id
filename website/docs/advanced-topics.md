---
layout: default
title: Advanced Topics
nav_order: 4
---

# Advanced Topics

## Performance Considerations

EncodedId uses a custom HashId implementation that is optimized for both speed and memory usage, significantly outperforming the original `hashids` gem.

### Benchmarks

Recent benchmarks show significant improvements:

```
| Test                      | Hashids (i/s) | EncodedId::HashId (i/s) | Speedup |
| ------------------------- | ------------ | --------------------- | ------- |
| #encode - 1 ID            |  131,000.979 |           197,586.231 |   1.51x |
| #decode - 1 ID            |   65,791.334 |            92,425.571 |   1.40x |
| #encode - 10 IDs          |   13,773.355 |            20,669.715 |   1.50x |
| #decode - 10 IDs          |    6,911.872 |             9,990.078 |   1.45x |
| #encode w YJIT - 1 ID     |  265,764.969 |           877,551.362 |   3.30x |
| #decode w YJIT - 1 ID     |  130,154.837 |           348,000.817 |   2.67x |
| #encode w YJIT - 10 IDs   |   27,966.457 |           100,461.237 |   3.59x |
| #decode w YJIT - 10 IDs   |   14,187.346 |            43,974.011 |   3.10x |
| #encode w YJIT - 1000 IDs |      268.140 |             1,077.855 |   4.02x |
| #decode w YJIT - 1000 IDs |      136.217 |               464.579 |   3.41x |
```

With YJIT enabled, performance improvements are even more significant, with up to 4x faster operation for large inputs.

### Memory Usage

Memory usage is also dramatically improved:

```
| Test                | Implementation   | Allocated Memory | Allocated Objects | Memory Reduction |
| ------------------- | ---------------- | ---------------- | ----------------- | ---------------- |
| encode small input  | Hashids          |          7.28 KB |               120 |                - |
|                     | EncodedId::HashId |            920 B |                 6 |           87.66% |
| encode large input  | Hashids          |        403.36 KB |              5998 |                - |
|                     | EncodedId::HashId |          8.36 KB |               104 |           97.93% |
| decode large input  | Hashids          |        366.88 KB |              5761 |                - |
|                     | EncodedId::HashId |         14.63 KB |               264 |           96.01% |
```

The memory usage improvements are dramatic, with up to 98% reduction in memory allocation for large inputs.

### Rails Performance Tips

For Rails applications with frequent encoded ID lookups:

1. **Use the Persists module**: When you frequently look up records by encoded ID, including `EncodedId::Rails::Persists` and adding the necessary database columns can significantly improve performance by avoiding the need to decode IDs.

2. **Be mindful of slugs**: Generating slugs can be expensive if the slug method performs complex operations. Keep your `name_for_encoded_id_slug` implementation efficient.

3. **Cache encoded IDs**: For records that rarely change, consider caching the encoded ID in a cache store like Redis or Memcached.

## Security Considerations

It's important to understand the security implications of using encoded IDs.

### Not for Sensitive Data

**Encoded IDs are not secure**. They are meant to be used for obfuscation, not encryption. It may be possible to reverse them via brute-force, especially for simple or sequential IDs.

Don't use encoded IDs as the sole protection for sensitive resources. Always implement proper authorization checks.

### Salt Management

The salt is critical to the encoding process. Keep these principles in mind:

1. **Use a strong salt**: Choose a salt that is at least 16 characters and includes mixed case, numbers, and special characters.

2. **Keep your salt secret**: Store it securely, such as in environment variables or credentials.

3. **Changing the salt**: If you change your salt, all previously encoded IDs will no longer decode correctly. Have a migration plan if you need to change the salt.

### Authorization vs. Obfuscation

Remember that encoded IDs provide obfuscation, not authorization:

```ruby
# WRONG - relying on encoded ID for security
def show
  @resource = Resource.find_by_encoded_id(params[:encoded_id])
  # No authorization check!
end

# RIGHT - with proper authorization
def show
  @resource = Resource.find_by_encoded_id(params[:encoded_id])
  authorize! :read, @resource  # Use your authorization library
end
```

## Hex Encoding Features (Experimental)

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

## Complex Use Cases

### Multiple Models with Same IDs

When you have multiple models with potentially overlapping IDs, using annotations helps distinguish them:

```ruby
# User with ID 123
user = User.find(123)
user.encoded_id  # => "user_p5w9-z27j"

# Product with ID 123
product = Product.find(123)
product.encoded_id  # => "product_p5w9-z27j"
```

This prevents collisions when decoding.

### Sharing Encoded IDs Across Applications

If you need to share encoded IDs across multiple applications:

1. **Use the same salt**: Ensure all applications use the same salt.
2. **Use the same encoding configuration**: Match alphabet, length, etc.
3. **Share the core library**: Use `encoded_id` gem in both applications.

```ruby
# Application A
coder = EncodedId::ReversibleId.new(salt: "shared-salt")
encoded = coder.encode(123)
# => "p5w9-z27j"

# Application B
coder = EncodedId::ReversibleId.new(salt: "shared-salt")
decoded = coder.decode("p5w9-z27j")
# => [123]
```

### Migration Strategies

When migrating to EncodedId or changing configuration:

1. **Dual reading**: Support both old and new formats temporarily.
2. **Gradual transition**: Introduce encoded IDs in new features first.
3. **URL redirects**: Set up redirects from old ID format to new.

```ruby
def find_by_any_id(id_param)
  # Try to treat as encoded ID first
  record = find_by_encoded_id(id_param)
  
  # Fall back to regular ID if encoded ID not found
  record ||= begin
    direct_id = id_param.to_i
    direct_id > 0 ? find_by(id: direct_id) : nil
  end
  
  record
end
```

## Troubleshooting

### Common Issues

#### Invalid Encoded ID Format

```
EncodedId::EncodedIdFormatError: Invalid input
```

This usually happens when:
- The encoded ID is malformed
- The salt doesn't match what was used to encode
- The alphabet configuration doesn't match

#### Encoded ID Length Exceeded

```
EncodedId::EncodedIdLengthError: (no message)
```

This happens when the encoded ID exceeds the configured maximum length. Solutions:
- Increase the `max_length` parameter
- Reduce the number of IDs being encoded together
- For hex strings, increase the `hex_digit_encoding_group_size`

### Debugging Tips

1. **Verify salt consistency**: Make sure you're using the same salt for encoding and decoding.

2. **Check configuration**: Ensure all configuration parameters match between encoding and decoding.

3. **Isolate the issue**: Try encoding and decoding simple IDs to verify basic functionality.

4. **Logging**: Add logging around encoding/decoding to see what's happening.

```ruby
begin
  decoded = coder.decode(encoded_id)
  Rails.logger.info("Decoded #{encoded_id} to #{decoded.inspect}")
rescue => e
  Rails.logger.error("Failed to decode #{encoded_id}: #{e.message}")
  raise
end
```

5. **Verify ID type**: Make sure you're not accidentally mixing hex encoding with regular encoding.