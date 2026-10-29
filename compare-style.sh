#!/usr/bin/env bash
# 같은 프롬프트를 출력 문체 없이와 있이 각각 헤드리스로 돌려 결과를 나란히 낸다.
#
# 출력 문체가 답변을 실제로 어떻게 바꾸는지 보려면 같은 질문에 두 번 답해야
# 한다. 사람이 두 세션을 띄워 비교하기 번거로워서 스크립트로 만든다.
#
# 사용법
#   bash compare-style.sh "프롬프트"
#   bash compare-style.sh -f 프롬프트파일
#   bash compare-style.sh "프롬프트" -o 결과폴더
#
# 결과 폴더에 세 파일을 쓴다.
#   prompt.txt  보낸 프롬프트
#   plain.md    출력 문체 없이 받은 원문
#   styled.md   Korean Plain으로 받은 결과
# 터미널에는 둘을 나란히 요약해 보여 준다.

set -u
cd "$(dirname "$0")" || exit 2

STYLE=output-styles/korean-plain.md
MODEL=${MODEL:-sonnet}
OUT=""
PROMPT=""

while [ $# -gt 0 ]; do
  case "$1" in
    -f) PROMPT=$(cat "$2") || exit 2; shift 2 ;;
    -o) OUT=$2; shift 2 ;;
    -m) MODEL=$2; shift 2 ;;
    *)  PROMPT=$1; shift ;;
  esac
done

[ -n "$PROMPT" ] || { echo "사용법: bash compare-style.sh \"프롬프트\" [-o 결과폴더]" >&2; exit 2; }
[ -r "$STYLE" ] || { echo "출력 문체 파일이 없습니다: $STYLE" >&2; exit 2; }
command -v claude >/dev/null || { echo "claude CLI가 없습니다" >&2; exit 2; }

if [ -z "$OUT" ]; then
  OUT=$(mktemp -d /tmp/style-compare.XXXXXX)
fi
mkdir -p "$OUT" || exit 2
printf '%s\n' "$PROMPT" > "$OUT/prompt.txt"

# 출력 문체는 한글 답변에만 적용된다. 두 실행 모두 한국어로 답하게 해서
# 언어 차이가 아니라 문체 차이만 남긴다.
BASE='한국어로 답하세요.'

echo "모델 $MODEL / 결과 $OUT"
echo

echo "[1/2] 출력 문체 없이..."
printf '%s\n\n%s' "$BASE" "$PROMPT" |
  claude -p --model "$MODEL" > "$OUT/plain.md" 2>"$OUT/plain.err"
rc1=$?

echo "[2/2] Korean Plain 적용..."
printf '%s\n\n%s' "$BASE" "$PROMPT" |
  claude -p --model "$MODEL" --append-system-prompt-file "$STYLE" \
  > "$OUT/styled.md" 2>"$OUT/styled.err"
rc2=$?

for n in plain styled; do
  if [ ! -s "$OUT/$n.md" ]; then
    echo "실패: $n.md가 비어 있습니다" >&2
    [ -s "$OUT/$n.err" ] && head -5 "$OUT/$n.err" >&2
    exit 2
  fi
done
[ "$rc1" = 0 ] && [ "$rc2" = 0 ] || echo "경고: 종료 코드 $rc1 / $rc2" >&2

echo
echo "===== 원문 (출력 문체 없이) ====="
cat "$OUT/plain.md"
echo
echo "===== Korean Plain 적용 ====="
cat "$OUT/styled.md"
echo
echo "===== 차이 ====="
pw=$(wc -w < "$OUT/plain.md" | tr -d ' ')
sw=$(wc -w < "$OUT/styled.md" | tr -d ' ')
pc=$(wc -m < "$OUT/plain.md" | tr -d ' ')
sc=$(wc -m < "$OUT/styled.md" | tr -d ' ')
printf '  분량   원문 %s어절 %s글자 -> 문체 %s어절 %s글자' "$pw" "$pc" "$sw" "$sc"
[ "$pc" -gt 0 ] && printf ' (%+d%%)' $(( (sc - pc) * 100 / pc ))
echo

# 제거 대상이 실제로 줄었는지 센다
for n in plain styled; do
  c=$(bash skills/technical-writing-ko/scan.sh "$OUT/$n.md" 2>/dev/null |
      awk '/제거 대상/{p=1} /후보 \(판단/{p=0} p' | grep -cE '^[0-9]')
  printf '  제거 대상  %-7s %s건\n' "$n" "$c"
done
echo
echo "  파일: $OUT"
