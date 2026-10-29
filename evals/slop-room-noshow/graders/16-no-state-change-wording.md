---
type: regex
match: not_contains
target: { source: file, path: result.md }
pattern: '취소(로| 상태로) (바꾼|바꿉)|(?<!상태를 )취소(로| 상태로) 변경'
---
