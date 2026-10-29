## [Unreleased]

### Changed

- The minimum alphabet size is enforced per encoder instead of by `EncodedId::Alphabet`. Sqids accepts alphabets of 3 or more unique characters; Hashids still requires at least 16. Both raise `EncodedId::InvalidAlphabetError` when the alphabet is too small. `EncodedId::Alphabet.new` no longer raises for alphabets with fewer than 16 unique characters, so the error is raised when the alphabet is used to build an encoder or configuration. Custom configurations that subclass `EncodedId::Encoders::BaseConfiguration` no longer inherit the 16-character minimum; any non-empty `Alphabet` is accepted, and the custom encoder is responsible for rejecting alphabets it cannot use.
- Encoder state is frozen after construction, so `Alphabet#unique_characters`, `Alphabet#equivalences`, `Blocklist#words`, `config.salt` and the `Hashid` ordinal readers (such as `salt_ordinals`) return frozen objects and raise `FrozenError` if mutated.

### Deprecated

- `EncodedId::Alphabet::MIN_UNIQUE_CHARACTERS` is deprecated. Use `EncodedId::Encoders::Hashid::MIN_ALPHABET_SIZE` or `EncodedId::Encoders::Sqids::MIN_ALPHABET_SIZE`.

### Fixed

- `ReversibleId#decode_hex` now enforces `max_length` and raises `EncodedId::EncodedIdFormatError` for malformed input, matching `#decode`. Previously it decoded input of any length, and raised `EncodedId::InvalidInputError` for malformed input. Hex or UUID IDs longer than `max_length` (128 by default) now raise `EncodedId::EncodedIdFormatError` on decode; set a larger `max_length`, or `max_length: nil`, if you issue them.

### Fixed (Rails integration)

- `find_by_encoded_id`, `find_by_encoded_id!`, `find_all_by_encoded_id`, `find_all_by_encoded_id!` and `where_encoded_id` now look records up by the model's primary key instead of a column literally named `id`. Models with a custom integer primary key (e.g. `self.primary_key = :widget_id`) previously raised `ActiveRecord::StatementInvalid`, or queried the wrong column if the table also had an `id` column. Models without a single-column primary key still use the `id` column.
- `EncodedId::Rails::ActiveRecordFinders` no longer warns for models with a custom integer primary key. It now warns when the primary key is missing, composite, string-based or otherwise not an integer column.

## [1.1.1] - 2026-10-07

### Fixed

- The Sqids encoder now only decodes strings that are the canonical encoding of the decoded values, matching the Hashids encoder. Previously many strings that were never issued (e.g. `"42"`) decoded to an ID, which let arbitrary strings resolve to records via the Rails finders.

### Upgrade notes

- **Sqids IDs must now match your current configuration exactly.** Previously Sqids accepted near-miss strings, which meant old IDs kept working after some config changes. They no longer do (Hashids has always behaved this way). Before upgrading, check whether you changed any of these after IDs were issued:
  - `id_length`: all IDs issued under the old length stop resolving.
  - the blocklist, `blocklist_mode` or `blocklist_max_length`: IDs that the new settings would issue differently (those containing a newly blocked word) stop resolving.
  - `downcase_on_decode` with an alphabet containing uppercase letters: IDs containing those letters stop resolving.

  Changing the separator, group size or character mappings is unaffected.

## [1.1.0] - 2026-01-23

### Added (Rails integration)

- Configuration in EncodedId Rails now supports all options from the core library

## [1.0.0] - 2025-11-21

- First stable release!

**Important!!: `:sqids` are not compatible with `:hashids`, DO NOT CHANGE FROM ONE TO THE OTHER AFTER GOING LIVE.**

### Fixed (Rails integration)

- Ensure finder methods correctly override their ActiveRecord counterparts 
- Warn when ActiveRecord integration used in model that doesn't use `id` as primary key

## [1.0.0.rc7] - 2025-11-19

### Breaking changes

- `ReversibleId` now no longer downcases the encodedid input string by default on decode, ie the `decode` option `downcase` is now `false`. This can be configured via the Rails configuration `downcase_on_decode` option.  In a future release the `downcase` option will be removed.
- The default encoding engine is now `:sqids` to reflect the official "deprecated" status of `Hashid`s (see https://sqids.org/faq#why-hashids)
- Ruby < 3.2 support dropped. The minimum supported Ruby version is now 3.2.0
- `Encoders` classes no longer expose `encode_hex` and `decode_hex` as they worked differently to the similarly named methods on ReversibleId
- Rails generator now needs you to specify which encoding algorithm you are using

### Added (Rails integration)

- `encoded_id_options` class method to override `encoded_id` configuration on a model by model basis
- Blocklist application "modes". User can decide if the blocklist checks should be applied in situations 
  where very long encoded IDs are likely and hence block word collisions are undesirably likely.

### Changed

- Blocklists are now pre-filtered to the encoder alphabet to avoid testing words which cannot be created by that alphabet anyway.
- Updates to inline RBS type signatures
- Documentation updates

## [1.0.0.rc6] - 2025-11-17

### Breaking changes

- Empty array inputs will now raise `InvalidInputError`

### Added

- Added support for [Sqids](https://sqids.org) as an alternative ID encoding engine. The default remains HashIds for backward compatibility. 
- New encoder abstraction layer allows switching between HashIds and Sqids via the `encoder: :sqids` or `encoder: :hashids` parameter to `ReversibleId.new`.
- Support for blocklists in both HashIds and Sqids encoders to prevent generating IDs containing specific words. Use the `blocklist` parameter with a `Set` or `Array` of strings to `ReversibleId.new`. For Hashids encodings, an error will be raised if a generated ID contains a blocklisted word. For Sqids a new ID is generated that does not contain the block word.

### Added (Rails integration)

- Merged `encoded_id-rails` gem into the monorepo
- Support for configuring the encoder and blocklist options in Rails through the configuration class
- `#encoded_id` now defaults to returning an 'annotated' ID, one in which a prefix is added to the encoded ID to indicate the 'type' of the record the ID represents. This can be disabled. IDs generated by older versions of this gem will decode correctly. But note that IDs generated by this version onwards will not decode correctly by older versions of this gem so make sure to disable annotation if you need to support older versions of this gem.
- New `EncodedId::Rails::Persists` module which adds hooks to the model to persist the encoded ID to the DB (see docs).
- `#encoded_id_hash` has been added to return only the encoded ID without an annotation prefix. If annotation is disabled, this method is basically an alias to `#encoded_id`.
- `.find_all_by_encoded_id` has been added to return all records matching the given encoded ID. This will return all matching records whose IDs are encoded in the encoded_id. Missing records are ignored.
- `.find_all_by_encoded_id!` like `.find_all_by_encoded_id` but raises an `ActiveRecord::RecordNotFound` exception if *any* of the records are not found.
- `Configuration#model_to_param_returns_encoded_id` to allow `EncodedId::Rails::Model` inclusion to also bring in `EncodedId::Rails::PathParam` automatically.

### Changed (Rails integration)

- `#name_for_encoded_id_slug` no longer provides a default implementation, it is up to the user to define this method, or configure the gem to use a different method name.
- `#slugged_encoded_id` no longer takes a `with:` parameter. To specify the name of the method to call to generate the slug, use the `slug_value_method_name` configuration option.

### Fixed (Rails integration)

- `#decode_encoded_id` now raises if the encoded ID is not a string.
- Handle more cases where a record held onto a memoized `encoded_id` even though its `id` had changed

## [1.0.0.rc5] - 2025-04-09

- `encoded_id` now uses its own implementation of `hashids` which is more efficient and has a smaller memory footprint. This massively reduces the GC churn in high-throughput applications. This is an implementation based on the original `hashids` gem but with many optimisations and improvements. Functionally it is identical to the original `hashids` gem.

## [1.0.0.rc4] - 2024-04-29

- Add an optional `max_inputs_per_id` argument to `ReversibleId`, thanks to [@avcwisesa](https://github.com/avcwisesa)
- The option `split_with:` can also now be set to nil to disable splitting of the encoded ID string

## [1.0.0.rc3] - 2023-10-23

- Add an optional `max_length` argument to `ReversibleId`, thanks to [@jugglebird](https://github.com/jugglebird)
- Alphabet validations to prevent whitespace and null chars
- Add `Alphabet#to_a`, `Alphabet#to_s`, `Alphabet#size` and a custom `Alphabet#inspect`
- Fixes to input validations
- hashids are case-sensitive, as are `Alphabet`s, however `ReversibleId` was always `downcase`ing the encodedid input string on decode. A new option has been added to `decode` and `decode_hex`, `downcase`, which defaults to `true`. Thus, the default behaviour is unchanged, but you can opt out to allow mixed case encodedid decode. *Note:* In V2 this will default to `false`.

## [1.0.0.rc2] - 2023-08-07

- `Alphabet` now has `#include?` and `#unique_charaters` methods

## [1.0.0.rc1] - 2023-08-06

- Improved RBS definitions
- Improved test coverage

## [0.4.0] - 2022-12-04

- Support custom 'split' character which must not be in the alphabet
- Ability to provide a custom character equivalence mapping

## [0.3.0] - 2022-10-12

- Fix splitting of encoded ID string
- Checks that integer values to be encoded are positive
- Experimental support for encoding hex strings

## [0.1.0] - 2022-10-11

- Initial release

## Rails Integration History

Before 1.0.0 the core gem and the Rails integration had separate version numbers but shared one set of git tags. `v0.0.3` and `v0.4.0` are core 0.3.0 and 0.4.0; `v0.0.1`, `v0.3.0`, `v0.3.1`, `v0.5.0`, `v0.6.0`, `v0.6.1` and `v0.6.2` are Rails 0.1.0, 0.3.0, 0.3.1, 0.5.0, 0.6.0, 0.6.1 and 0.6.2. Core 0.1.0 and Rails 0.2.0 and 0.4.0 were not tagged.

## [1.0.0.beta3] - 2024-04-29

These changes are also listed under 1.0.0.rc6 (Rails integration).

- Drop support for Ruby 2.7.
- `#decode_encoded_id` raises if the encoded ID is not a string.
- An `EncodedId::InvalidInputError` while decoding is handled in the same way as `EncodedId::EncodedIdFormatError`.
- Allow `character_group_size` and `separator` options to be set to `nil`.

## [1.0.0.beta2] - 2023-10-23

- Require `encoded_id` 1.0.0.rc3, which addresses GHSA-3px7-jm2p-6h2c.
- Raise `ArgumentError` when a configured separator is in the alphabet or clashes with another separator.

## [1.0.0.beta1] - 2023-08-07

These changes are also listed under 1.0.0.rc6 (Rails integration).

- `#encoded_id` returns an annotated ID by default.
- Add `#encoded_id_hash`, `.find_all_by_encoded_id` and `.find_all_by_encoded_id!`.
- `#slugged_encoded_id` uses the method set by `slug_value_method_name` and no longer takes `with:`.
- `#name_for_encoded_id_slug` no longer has a default implementation.
- `#to_param` raises when the record has no encoded ID.

## [0.6.2] - 2023-02-09

- Fix `encoded_id` memoization clearing when record is duplicated

## [0.6.1] - 2023-02-09

- Fix `#encoded_id` to return nil if `#id` is nil
- Ensure `encoded_id` memoization is cleared when record is duplicated, or id changes

## [0.6.0] - 2022-12-21

- Rename mixin to `Model`
- Introduce optional mixins for overriding `#to_param`

## [0.5.0] - 2022-12-21

- `name_for_encoded_id_slug` no longer uses the return value from name but rather just uses the `class` `name`.
- If you want to change the name used in the slug, override `name_for_encoded_id_slug`

## [0.4.0] - 2022-12-18

- Refactor internals, remove any methods not actually related to creating `encoded_id`, (eg `slugged_id` was removed).

## [0.3.1] - 2022-12-15

- Fix default config

## [0.3.0] - 2022-12-15

- Updates gem `encoded_id` dependency and fixes configuration

## [0.2.0] - 2022-12-14

- No notes...

## [0.1.0] - 2022-11-17

- Initial release of Rails integration