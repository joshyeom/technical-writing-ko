---
type: regex
match: not_contains
target: { source: file, path: result.md }
pattern: '^(?![\s\S]*(회의록 봇이|결정 사항 1개|회의가 끝나면))[\s\S]*카드'
---
