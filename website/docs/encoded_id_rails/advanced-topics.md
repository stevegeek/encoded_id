---
layout: default
title: Advanced Topics
parent: EncodedId::Rails
nav_order: 4
---

# Advanced Topics
{: .no_toc }

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

## Performance Considerations

For Rails applications with frequent encoded ID lookups:

1. **Use the Persists module**: When you frequently look up records by encoded ID, including `EncodedId::Rails::Persists` and adding the necessary database columns can significantly improve performance by avoiding the need to decode IDs.

2. **Be mindful of slugs**: Generating slugs can be expensive if the slug method performs complex operations. Keep your `name_for_encoded_id_slug` implementation efficient.

3. **Cache encoded IDs**: For records that rarely change, consider caching the encoded ID in a cache store like Redis or Memcached.

For general encoder performance (Sqids vs HashIds), see [EncodedId Advanced Topics](../encoded_id/advanced-topics.html#performance-considerations).

## Security Considerations

It's important to understand the security implications of using encoded IDs.

### Not for Sensitive Data

**Encoded IDs are not secure**. They are meant to be used for obfuscation, not encryption. It may be possible to reverse them via brute-force, especially for simple or sequential IDs.

Don't use encoded IDs as the sole protection for sensitive resources. Always implement proper authorization checks.

```ruby
class PostsController < ApplicationController
  def show
    @post = Post.find_by_encoded_id!(params[:id])

    # Always check authorization!
    authorize! :read, @post  # Use your authorization library
  end
end
```

Read more about the security implications: [Hashids expose salt value](https://www.sjoerdlangkemper.nl/2023/11/25/hashids-expose-salt-value/)

## Salts

**Changing the salt**: If you change your salt, all previously encoded IDs will no longer decode correctly. Have a migration plan if you need to change the salt.

**Per-model salts**: You can configure different salts for different models by overriding the `encoded_id_salt` class method. See the [Configuration](configuration.html#salt-configuration) documentation for details.
