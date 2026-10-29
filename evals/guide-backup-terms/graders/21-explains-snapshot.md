---
type: regex
match: not_contains
target: { source: file, path: result.md }
pattern: '^(?![\s\S]*사본)[\s\S]*스냅샷'
---
