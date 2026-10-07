# Tokens

`schema.ts` is the canonical role and type vocabulary. `defaults/` contains
source-traced Material data, while validation, CSS generation, serialization,
contrast, and component registration each have one explicit module.

Component tasks register their own sourced `--m3e-comp-*` values through
`defineComponentTokens`. T02 intentionally ships an empty component registry;
placeholder component values do not belong here.
