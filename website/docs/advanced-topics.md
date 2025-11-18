---
layout: default
title: Advanced Topics
nav_order: 4
---

# Advanced Topics

## Performance Considerations

In general, at the moment, Sqids are slower to encode than Hashids (especially if using the blocklist feature). However, they are faster to decode than Hashids. However, with YJIT enabled the differences in speeds are smaller.

To get the most out of Sqids encode performance consider a small (or no) blocklist (set the `blocklist:` option). The default Sqids blocklist is very costly on encode time, but extensive.

For Rails applications with frequent encoded ID lookups:

1. **Use the Persists module**: When you frequently look up records by encoded ID, including `EncodedId::Rails::Persists` and adding the necessary database columns can significantly improve performance by avoiding the need to decode IDs.

2. **Be mindful of slugs**: Generating slugs can be expensive if the slug method performs complex operations. Keep your `name_for_encoded_id_slug` implementation efficient.

3. **Cache encoded IDs**: For records that rarely change, consider caching the encoded ID in a cache store like Redis or Memcached.

## Security Considerations

It's important to understand the security implications of using encoded IDs.

### Not for Sensitive Data

**Encoded IDs are not secure**. They are meant to be used for obfuscation, not encryption. It may be possible to reverse them via brute-force, especially for simple or sequential IDs.

Don't use encoded IDs as the sole protection for sensitive resources. Always implement proper authorization checks.

Read more about the security implications: [Hashids expose salt value](https://www.sjoerdlangkemper.nl/2023/11/25/hashids-expose-salt-value/)

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