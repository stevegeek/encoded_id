## [Unreleased]

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

- Initial release
