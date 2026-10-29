---
type: regex
match: not_contains
target: { source: file, path: result.md }
pattern: '해결(로| 상태로) (바꾼|바꿉)|(?<!상태를 )해결(로| 상태로) 변경'
---
