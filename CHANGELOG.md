## [Unreleased]

## [2.0.0.alpha1] - unreleased

### Breaking changes

- `ReversibleId` now no longer downcases the encodedid input string by default on decode, ie the `decode` option `downcase` is now `false`. In a future release the `downcase` option will be removed. Generation of the encoded ID is 1.5 times faster and uses less memory.

## [1.0.0] - unreleased

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
