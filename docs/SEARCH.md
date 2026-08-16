# MaybeLater — Search Specification

## Primary Search Engine

SQLite FTS5.

Search fields:

- OCR text
- manual tags
- image labels

## User Input

Users should type normal text.

Examples:

oauth
python error
fiverr
payment
redirect uri
client id

They should not need to know FTS5 syntax.

## Query Normalization

Handle:

- whitespace
- punctuation
- quotes
- apostrophes
- hyphens
- numbers
- special characters
- empty queries
- accidental FTS operators

Never concatenate raw user input into SQL.

Use parameterized queries.

## Debounce

Approximately 250–300ms.

Do not search for every keystroke.

## Ranking

Prefer:

1. exact/strong OCR match
2. phrase match
3. prefix match
4. manual tag match
5. image-label match
6. weak recency tie-breaker

An old highly relevant screenshot must beat a recent weakly relevant screenshot.

## Results

Each result should provide:

- screenshot ID
- thumbnail path
- matched snippet
- collection
- tags
- date

## Snippets

Do not display huge OCR text.

Show a concise matched snippet.

Highlight matching terms.

## Filters

Architecture should allow:

- collection
- favorites
- date
- trash exclusion

without rewriting the search engine.

## Performance

Target sub-100ms typical query response on a reasonable device with around 10,000 indexed records.

Do not fake benchmark numbers.

Measure actual performance.

## Search History

Store recent searches.

Keep it bounded, e.g. 20–50 items.

Allow clearing.

## FTS Rebuild

Provide a rebuild mechanism.

The screenshots table is canonical.

FTS can be deleted and rebuilt from canonical data.
