---
type: regex
match: not_contains
target: { source: file, path: result.md }
flags: m
pattern: '^(?!.*(고무나무|서버|이미지)).*(한|두|세|네|[0-9]) ?(마리|자루|짝|척|벌|켤레|그루|채)'
---
