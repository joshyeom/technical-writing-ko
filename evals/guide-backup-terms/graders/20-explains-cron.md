---
type: regex
match: not_contains
target: { source: file, path: result.md }
pattern: '^(?![\s\S]*(정해진 시각|자동으로|자동 실행|예약된 작업|예약 작업))[\s\S]*크론'
---
