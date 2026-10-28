#!/usr/bin/env bash
# 규칙 결함을 찾아 개선안까지 만들고 멈춘다. 규칙 파일은 고치지 않는다.
#
# codex와 이 스킬로 같은 글을 윤문해 비교하면, 두 쪽이 서로 다른 유형을
# 놓친다. 그 차이가 규칙 문구의 결함을 드러낸다(실측: 원칙 1의 주어 삭제,
# 판별법 3의 `확인한다` 통일). 이 스크립트는 그 비교를 준비하고 결과를
# 모아 둔다. 무엇이 옳은 윤문인지는 사람이 정하므로, 개선안을 적어 두고
# 멈춘다. 규칙 파일 수정과 커밋은 하지 않는다.
#
# 사용법
#   bash improve-loop.sh <사례폴더>      # 회차 준비와 채점기 검증
#   bash improve-loop.sh <사례폴더> -s   # 채점만 (윤문 결과를 넣은 뒤)
#
# 사례 폴더에 두 파일이 있어야 한다.
#   src.md        문제를 심은 글
#   expected.txt  `찾을 문구|설명` 한 줄에 하나
# 선택
#   clean.md      규칙에 맞게 쓴 글. 바뀌면 오탐이다
#   keep.txt      규칙이 원문 유지를 요구하는 항목. `문구<TAB>보고를 찾을 정규식`
#                 정규식에 `|`를 쓸 수 있도록 탭으로 가른다
#                 미해결 절이 그 정규식에 맞으면 정상 동작이다. 보고는 원문을
#                 글자대로 인용하지 않으므로(`원문의 \`사람\`이`) 문구로 찾으면
#                 규칙대로 동작한 실행을 실패로 집계한다(실측)

set -u
cd "$(dirname "$0")" || exit 2

SKILL=skills/technical-writing-ko/SKILL.md
SCAN=skills/technical-writing-ko/scan.sh
RUNS=${RUNS:-3}

DIR=${1:-}
MODE=${2:-prepare}
[ -n "$DIR" ] || { echo "사용법: bash improve-loop.sh <사례폴더> [-s]" >&2; exit 2; }
for f in "$DIR/src.md" "$DIR/expected.txt" "$SKILL" "$SCAN"; do
  [ -r "$f" ] || { echo "파일을 읽을 수 없습니다: $f" >&2; exit 2; }
done

want=$(grep -cE '.' "$DIR/expected.txt")

# 본문만 채점한다. `## 미해결` 절은 고친 글이 아니라 무엇을 못 고쳤는지
# 적은 보고이고, 거기서 원문을 인용하는 것은 규칙이 요구한 동작이다.
score() {
  local f=$1 n=0 pat label
  local body; body=$(awk '/^## 미해결/{exit} {print}' "$f")
  local note; note=$(sed -n '/^## 미해결/,$p' "$f")
  while IFS='|' read -r pat label; do
    [ -n "$pat" ] || continue
    printf '%s\n' "$body" | grep -qF "$pat" || continue
    local kre=''
    [ -r "$DIR/keep.txt" ] && kre=$(awk -F'\t' -v p="$pat" '$1==p {print $2}' "$DIR/keep.txt")
    if [ -n "$kre" ]; then
      # 규칙이 원문 유지를 요구한 항목이다. 미해결 보고가 있으면 규칙대로 동작했다.
      if printf '%s\n' "$note" | grep -qE "$kre"; then
        printf '  정상  %-24s 원문 유지 + 미해결 보고\n' "$pat"
        continue
      fi
      printf '  남음  %-24s %s (미해결 보고 없음)\n' "$pat" "$label"
      n=$((n+1)); continue
    fi
    printf '  남음  %-24s %s\n' "$pat" "$label"
    n=$((n+1))
  done < "$DIR/expected.txt"
  echo "누락 ${n}건"
}

if [ "$MODE" = "-s" ]; then
  echo "===== 채점 ====="
  miss_total=0
  for d in "$DIR"/r*/ "$DIR"/codex/; do
    [ -r "$d/out.md" ] || continue
    printf -- '--- %s ---\n' "${d%/}"
    out=$(score "$d/out.md"); printf '%s\n' "$out"
    m=$(printf '%s' "$out" | sed -n 's/^누락 \([0-9]*\)건$/\1/p')
    miss_total=$((miss_total + ${m:-0}))
  done
  echo "  합계 누락 ${miss_total}건"

  if [ -r "$DIR/clean.md" ] && [ -r "$DIR/cv/out.md" ]; then
    echo
    echo "===== 대조군 (오탐) ====="
    if diff -q "$DIR/clean.md" "$DIR/cv/out.md" >/dev/null; then
      echo "  바이트 동일. 오탐 0건"
    else
      echo "  바뀌었습니다. 규칙에 맞는 문장을 고쳤는지 확인하세요."
      diff "$DIR/clean.md" "$DIR/cv/out.md" | sed 's/^/    /'
    fi
  fi

  echo
  echo "===== codex와 스킬이 다르게 고친 곳 ====="
  if [ -r "$DIR/codex/out.md" ] && [ -r "$DIR/r1/out.md" ]; then
    diff "$DIR/r1/out.md" "$DIR/codex/out.md" | sed 's/^/  /'
    echo
    echo "  위 차이를 두 가지로 가르세요."
    echo "    규칙 위반  -> 결함 후보. 규칙 문구를 고칠 근거입니다"
    echo "    취향 차이  -> 버립니다. 둘 다 규칙을 지켰으면 결함이 아닙니다"
  else
    echo "  codex/out.md 또는 r1/out.md가 없습니다"
  fi

  echo
  echo "===== 사람이 정할 것 ====="
  cat <<'NOTE'
  결함 후보를 규칙 문구로 옮기기 전에 두 가지를 가르세요.
    문구를 더 분명히 쓰는 수정   -> 자동으로 진행해도 됩니다
    무엇이 옳은 윤문인지 정하는 수정 -> 사용자가 정합니다

  뒤쪽에 해당하면 개선안만 적고 멈춥니다. 원칙의 뜻, 무엇을 미해결로
  남길지, 어미와 서식 정책이 여기 해당합니다. 2026-10-28 원칙 1 수정
  ('주어를 삭제하지 말고 미해결로 밝힌다')이 그랬습니다.
NOTE
  exit 0
fi

echo "===== 1. 채점기 검증 ====="
echo "  expected.txt 항목 ${want}개"
got=$(score "$DIR/src.md" | sed -n 's/^누락 \([0-9]*\)건$/\1/p')
echo "  원본 채점 결과 ${got}건"
if [ "${got:-0}" != "$want" ]; then
  echo "  어긋납니다. 심은 문제를 채점기가 다 찾지 못합니다."
  echo "  expected.txt의 문구가 src.md와 글자까지 같은지 확인하세요."
  echo "  이 단계를 건너뛰면 규칙이 동작하지 않는데 통과로 집계됩니다."
  exit 1
fi
echo "  통과. 심은 문제를 모두 찾습니다."

echo
echo "===== 2. 회차 폴더 ====="
for i in $(seq 1 "$RUNS"); do mkdir -p "$DIR/r$i" && cp "$DIR/src.md" "$DIR/r$i/"; done
mkdir -p "$DIR/codex" && cp "$DIR/src.md" "$DIR/codex/"
echo "  스킬 ${RUNS}회: $DIR/r1 .. r${RUNS}"
echo "  codex 1회: $DIR/codex"
if [ -r "$DIR/clean.md" ]; then
  mkdir -p "$DIR/cv" && cp "$DIR/clean.md" "$DIR/cv/src.md"
  echo "  대조군: $DIR/cv"
fi

echo
echo "===== 3. 윤문 지시 ====="
cat <<NOTE
  스킬 회차마다 (subagent, sonnet):
    규칙: $PWD/$SKILL
    대상: $DIR/r<N>/src.md  ->  결과: $DIR/r<N>/out.md
    검사: bash $PWD/$SCAN <결과>  (제거 대상 0건까지)
    규칙이 미해결로 밝히라고 한 것은 결과 끝에 '## 미해결' 절로 적게 한다

  codex 1회 (codex:codex-rescue):
    같은 규칙, 대상 $DIR/codex/src.md -> $DIR/codex/out.md
    codex는 작업 폴더에 쓰지 못한다. ~/technical-writing-ko 안으로
    복사해 작업시킨 뒤 결과를 옮긴다(실측: 샌드박스 차단)

  끝나면: bash improve-loop.sh $DIR -s
NOTE
