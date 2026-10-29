---
type: regex
match: not_contains
target: { source: file, path: result.md }
pattern: '^(?!.*(메신저|메일)).*두 곳'
flags: m
---
