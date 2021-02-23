# EncodedId 

## coming soon as a Gem

Todo...

## Features

Build with https://hashids.org

* Hashids are reversible, no need to persist the generated Id 
* we don't override any methods or mess with ActiveRecord 
* we support slugged IDs (eg 'beef-tenderloins-prime--p5w9-z27j') 
* we support multiple model IDs encoded in one `EncodedId` (eg '7aq6-0zqw' decodes to `[78, 45]`)
* we use a reduced character set (Crockford alphabet), 
  and ids split into groups of letters, ie we aim for 'human-readability'


## Compared to alternate Gems

- https://github.com/excid3/prefixed_ids
- https://github.com/namick/obfuscate_id
- https://github.com/norman/friendly_id
- https://github.com/SPBTV/with_uid

## See also

- https://hashids.org
- https://www.crockford.com/wrmg/base32.html


## keywords 
hash ID, friendly ID, obfuscate ID, rails, ActiveRecord, model, slug, vanity URL, friendly URL
