---
type: regex
match: not_contains
target: { source: file, path: result.md }
flags: m
pattern: '^(?!.*유니폼).*(한|두|세|네|[0-9]) ?벌'
---
