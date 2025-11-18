---
layout: default
title: Similar Gems
nav_order: 4
permalink: /docs/similar-gems/
---

# EncodedId compared to other gems
{: .no_toc }

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

---

The Ruby ecosystem offers 20+ great alternative gems for ID obfuscation, encoding, encryption, and slug generation.

This page compares EncodedId with these alternatives, organized by approach, so you can decide which one might work
for your use-case.

**This is not a value judgement on these other gems, they are all great!**

Note that internally `encoded_id` has more optimised versions of `hashids.rb` and `sqids-ruby`, so performance might
generally be better in EncodedID than gems that depend on the original encoding gems. I do intend to upstream these
performance improvements to the original gems as soon as possible so all gems benefit.

## Gems for obfuscating IDs

### [hashids.rb](https://rubygems.org/gems/hashids)

The original Ruby implementation of the Hashids algorithm, generating YouTube-like short IDs from integers using a salt-based alphabet shuffling.

Key differences to EncodedId:
- No Rails integration built-in, but used in various other Rails integrations
- No character grouping or slug support
- No profanity filtering
- Has been officially rebranded to Sqids

#### EncodedId as an alternative?

EncodedId can fully replace `hashids.rb` since it supports the Hashids algorithm and adds comprehensive Rails integration, character grouping, slugs, profanity filtering, and Hash length limits.

### [sqids-ruby](https://rubygems.org/gems/sqids)

The modern successor to Hashids with a simplified algorithm and better encoding efficiency using base 61 encoding versus Hashids' base 49.

Key differences to EncodedId:
- Produces shorter IDs than Hashids with the same input
- Enhanced profanity filtering
- No Rails integration built-in, get it from sqids-rails gem
- No character grouping, slugs, or prefixes
- Eliminated confusing "salt" parameter in favor of shuffled alphabets

#### EncodedId as an alternative?

EncodedId fully supports Sqids and can replace `sqids-ruby`, offering additional Rails integration, character grouping, slugs, and Hash length limits that sqids-ruby lacks.

### [hashid-rails](https://rubygems.org/gems/hashid-rails)

Seamless ActiveRecord integration for Hashids with automatic `to_param` override and enhanced `find` methods.

Key differences to EncodedId:
- Hashid signing (signature token) to prevent conflicts between database IDs and hashids
- Dual-mode AR `find` accepts both hashids and regular IDs (in EncodedID this is optional)
- No character grouping, slugs, or Hash length limits
- Only supports Hashids, not Sqids
- Per-model configuration limited to salt, minimum length, and alphabet

#### EncodedId as an alternative?

EncodedId Rails is a complete alternative offering Hashids support with Rails integration, plus character grouping, slugs, and Hash length limits.

However, `hashid-rails` has a hashid 'signing' feature that EncodedId doesn't implement yet.

### [sqids-rails](https://rubygems.org/gems/sqids-rails)

ActiveRecord integration for Sqids with `has_sqid` declarations supporting multiple sqid fields per model with different configurations.

Key differences to EncodedId:
- Supports multiple sqid fields per model (e.g., `has_sqid :long_sqid, min_length: 24`)
- Only supports Sqids, not Hashids
- No character grouping, slugs, or prefixes
- No profanity filtering configuration

#### EncodedId as an alternative?

EncodedId supports Sqids with Rails integration and adds character grouping, slugs, and prefixes.

However, if you need multiple sqid fields per model with different configurations, `sqids-rails` offers this specific capability
that EncodedId doesn't provide.

### [idy](https://rubygems.org/gems/idy)

Simple ActiveRecord ID obfuscator using Hashids internally with minimal configuration.

Key differences to EncodedId:
- Only provides `find_by_idy` method (no other finder methods)
- No character grouping, slugs, prefixes, or profanity filtering

#### EncodedId as an alternative?

EncodedId can replace `idy` with more features (character grouping, slugs, profanity filtering etc).

### [prefixed_ids](https://rubygems.org/gems/prefixed_ids)

Generates Stripe-style prefixed IDs like `user_5vJjbzXq9KrLEMm32iAnOP0xGDYk6dpe` using Hashids with table names as part of the salt.

Key differences to EncodedId:
- Global cross-model lookup: `PrefixedIds.find("user_5vJj...")` works across all models
- No character grouping or slugs (prefixes only)
- No hash length protection
- Optional `has_many` override for prefix ID helpers

#### EncodedId as an alternative?

EncodedId supports Stripe-style prefixes through its annotation system and includes numerous other features, but `prefixed_ids` offers the unique global cross-model lookup with `PrefixedIds.find()` that works across all models without knowing the model class; a feature EncodedId doesn't provide.

### [cool_id](https://rubygems.org/gems/cool_id)

Generates prefixed random IDs for Rails models using nanoid-style generation, producing IDs like `usr_vktd1b5v84lr`.

Key differences to EncodedId:
- Random ID generation (not reversible encoding) stored in the AR record (EncodedID can optionally be configured to persist encoded IDs)
- No external dependencies - implements nanoid-style generation internally
- Global lookup via `CoolId.locate("usr_vktd1b5v84lr")` finds records across all models
- Can target alternate columns via `id_field:` option while maintaining traditional primary keys
- Configurable alphabet, length, and separator
- No character grouping or slugs

#### EncodedId as an alternative?

`cool_id` generates random, non-reversible IDs and has global cross-model lookup. EncodedId uses reversible encoding of existing IDs and can persist those, but does not provide a global lookup.

If you want random generation with prefixes and global lookup, `cool_id` is purpose-built for that.

### [cloak_id](https://rubygems.org/gems/cloak_id)

ActiveRecord-specific obfuscation using a prime number-based reversible hash encoded as strings.

Key differences to EncodedId:
- Uses prime number-based hash instead of Hashids/Sqids
- `find` automatically detects cloaked or numeric IDs

#### EncodedId as an alternative?

Yes EncodedId could be used as an alterative to `cloak_id`, but if `cloak_id`s prime number-based algorithm might be of interest to you then check it out.

### [obfuscate_id](https://rubygems.org/gems/obfuscate_id) and [obfuscatable](https://rubygems.org/gems/obfuscatable)

Transforms sequential IDs into random-looking 10-digit numerical strings using the ScatterSwap algorithm.

Key differences to EncodedId:
- Produces purely **numeric output** (10 digits) vs alphanumeric
- Each number 0-9,999,999,999 maps to unique number in same range

#### EncodedId as an alternative?

Not a direct replacement but it is a more feature complete alternative. `obfuscate_id` produces purely numeric output (10 digits), which may be preferable for certain use-cases.

### [sequenced](https://rubygems.org/gems/sequenced)

Generates scoped unique sequential IDs for ActiveRecord models that provide
another way to select a record without needing/exposing the primary key.

Key differences to EncodedId:
- Provides **sequential numbering**, not obfuscation
- `acts_as_sequenced` macro
- Completely different use case (sequential vs obfuscated)

#### EncodedId as an alternative?

Not a replacement. `sequenced` generates sequential numbering (not obfuscation) for use cases like invoice numbers or per-parent sequences—completely different from EncodedId's purpose of obfuscating IDs.

### [based_uuid](https://rubygems.org/gems/based_uuid) / [youyouaidi](https://rubygems.org/gems/youyouaidi) / [shortuuid](https://rubygems.org/gems/shortuuid)

Encodes UUIDs to Base32 or Base62 or other alphabets to reduce the size of the UUID. Some support
optional Stripe-style prefixes, and ActiveRecord integration

#### EncodedId as an alternative?

EncodedId can encode UUIDs but if you just need to reduce the size of UUIDs then `shortuuid`, `based_uuid` etc will serve
you better.

### [ulid](https://rubygems.org/gems/ulid)

Generates Universally Unique Lexicographically Sortable Identifiers using 128-bit structure with 48-bit timestamp plus 80-bit cryptographic randomness.

Key differences to EncodedId:
- **Lexicographically sortable** (database index friendly)
- Time-ordered with millisecond timestamp component
- 28% shorter than standard UUID (26 vs 36 characters)
- Optional custom timestamps for reproducible ULIDs
- Timestamp component is extractable (reduced privacy)
- Author recommends UUID v7 instead for new projects

#### EncodedId as an alternative?

Not a replacement. `ulid` generates time-ordered, lexicographically sortable identifiers with timestamp components.

## Database-Stored Alternate Identifiers

### [FriendlyId](https://rubygems.org/gems/friendly_id)

The most popular slug generation solution for Rails. Instead of encoding IDs, it generates and stores human-readable slugs in the database.

Key differences to EncodedId:
- Stores slugs in database columns (requires schema changes) - Persistance of encoded IDs in `encoded_id-rails` is optional
- History tracking maintains all previous slugs to prevent broken links
- Collision handling automatically appends sequences for duplicates
- Reserved words prevention protects system route conflicts

#### EncodedId as an alternative?

Yes `encoded_id-rails` can be used as an alternative. Both offer a rich set of features which don't completely overlap. 

So I recommend you read over the features of both to decide which one to go for!

### [slugged](https://rubygems.org/gems/slugged)

Minimal slug implementation.

Key differences to EncodedId:
- Stores slugs in database (requires schema changes)
- Slug history support 

#### EncodedId as an alternative?

Yes but `slugged` allows for slug-only IDs while EncodedId adds the slug to an encoded version of the numeric ID (the slug
is only cosmetic).

## Encryption-Based Solutions

These gems provide actual encryption rather than obfuscation, making them suitable for secure data transmission.

**EncodedId cannot be used as an alternative to these gems! EncodedId encodings are not secure at the moment!**

### [URLcrypt](https://rubygems.org/gems/urlcrypt)

Uses 256-bit AES symmetric encryption with modified Base32 encoding specifically designed for URL safety.

Key differences to EncodedId:
- Provides actual encryption, not just obfuscation
- Dual mode: encrypt/decrypt for security OR encode/decode for basic encoding
- Suitable for secure data transmission vs just hiding sequential IDs

### [encoded_token](https://rubygems.org/gems/encoded_token)

Encodes record IDs or UUIDs into secure tokens using encryption ciphers generated from an integer seed.

Key differences to EncodedId:
- Designed for password reset links, email confirmations, invitation links
- Filters invalid requests before database queries (no DB search needed)

### [has_secure_token](https://api.rubyonrails.org/classes/ActiveRecord/SecureToken/ClassMethods.html)

Built into Rails. Generates secure random tokens stored in database columns.

Key differences to EncodedId:
- Stores random tokens in database columns
- Common for API keys, reset tokens
- Automatic uniqueness validation
- Not reversible or based on existing IDs

### [obfuscate](https://rubygems.org/gems/obfuscate)

Uses Blowfish block cipher encryption producing 11-character obfuscated IDs in block mode.

Key differences to EncodedId:
- Uses Blowfish cipher instead of Hashids/Sqids
- Two modes: `:block` for numeric IDs (max 99,999,999) and `:string` for text obfuscation
- Fixed 11-character output for block mode

### [integer-obfuscator](https://rubygems.org/gems/integer-obfuscator)

Implements Skip32 cipher (based on SKIPJACK) for obfuscating 32-bit integers with bijective transformation.

Key differences to EncodedId:
- Uses Skip32 cipher (SKIPJACK-based)
- Limited to 32-bit integers only
- Example: 1→418026769, 2→1524067781


## Feature Comparison Table

| Gem | Algorithm | Rails Integration | URL-Safe | Data Types          |
|-----|-----------|-------------------|----------|---------------------|
| **encoded-id** | Hashids/Sqids | Excellent | Yes | Int, Hex, Multi     |
| hashids.rb | Hashids | None | Yes | Int, Hex, Multi     |
| sqids-ruby | Sqids | Via sqids-rails | Yes | Int, Multi          |
| hashid-rails | Hashids | Excellent | Yes | Int, Multi          |
| sqids-rails | Sqids | Excellent | Yes | Int, Multi          |
| idy | Hashids | ActiveRecord | Yes | Int                 |
| prefixed_ids | Hashids | ActiveRecord | Yes | Int                 |
| cool_id | Nanoid (random) | ActiveRecord | Yes | N/A                 |
| cloak_id | Prime hash | Excellent | Yes | Int                 |
| obfuscate_id | Scatter swap | ActiveRecord | Yes | Int (numeric)       |
| obfuscatable | Scatter swap | ActiveRecord | Yes | Int (numeric)       |
| sequenced | Sequential | ActiveRecord | N/A | Int                 |
| based_uuid | Base32 | ActiveRecord | Yes | UUID                |
| shortuuid | Base62 | Standalone | Yes | UUID, Int           |
| youyouaidi | Base-encoding | Basic | Yes | UUID                |
| ulid | Crockford Base32 | Basic | Yes | Timestamp + Random  |
| FriendlyId | Slug (stored) | Excellent | Yes | String slugs        |
| slugged | Slug (stored) | ActiveRecord | Yes | String slugs        |
| URLcrypt | AES-256 + Base32 | Good | Yes | Binary data         |
| encoded_token | Encryption cipher | Good | Yes | Int, UUID           |
| has_secure_token | Random (stored) | Built-in Rails | Yes | Random tokens       |
| obfuscate | Blowfish cipher | ActiveRecord | Yes | Int (<100M), String |
| integer-obfuscator | Skip32 cipher | Standalone | Yes | Int (32-bit)        |

