#!/usr/bin/env bash
# 이 저장소 문서가 이 저장소 규칙을 지키는지 검사한다.
#
# scan.sh는 글 하나를 검사한다. 이 스크립트는 저장소 전체를 검사하고,
# scan.sh가 보지 않는 것을 하나 더 본다. SKILL.md 표가 "쓰지 않는다"로
# 지정한 말을 문서가 자기 목소리로 쓰는지다. 금지어 목록을 여기 적지 않고
# SKILL.md 표에서 읽어 오므로, 표를 고치면 검사도 따라 바뀐다.
#
# 사용법: bash self-check.sh
# 종료 코드: 0 통과, 1 위반, 2 검사 못 함

set -u
cd "$(dirname "$0")" || exit 2

SKILL=skills/technical-writing-ko/SKILL.md
SCAN=skills/technical-writing-ko/scan.sh
DOCS=(README.md INSTALL.md evals/README.md "$SKILL"
      skills/technical-writing-ko/new-document.md
      output-styles/korean-plain.md)

for f in "$SKILL" "$SCAN" "${DOCS[@]}"; do
  [ -r "$f" ] || { echo "파일을 읽을 수 없습니다: $f" >&2; exit 2; }
done

fail=0

# 본문만 남긴다. 코드 블록, 표, Don't/Do 인용, 백틱 안은 규칙을 설명하려고
# 금지어를 일부러 쓰는 곳이라 검사에서 뺀다.
prose() {
  awk '
    /^[[:space:]]*```/ { inblock = !inblock; next }
    inblock            { next }
    /^[[:space:]]*\|/  { next }
    /^[[:space:]]*>/   { next }
    /^(name|description|license|allowed-tools):/ { next }
    { gsub(/`[^`]*`/, ""); print FNR "\t" $0 }
  ' "$1"
}

# README가 예외로 적어 둔 건수. 이 수와 같으면 통과로 본다. 늘어나면
# 새로 생긴 위반이라 종료 코드 1로 알린다.
EXPECTED_GATE=2   # README가 예외로 적어 둔 건수

echo "===== 1. 제거 대상 (scan.sh, 문서마다) ====="
gate_total=0
for f in "${DOCS[@]}"; do
  out=$(bash "$SCAN" "$f" 2>&1); rc=$?
  [ "$rc" = 2 ] && { echo "검사 실패: $f"; echo "$out" >&2; exit 2; }
  n=$(printf '%s\n' "$out" |
      awk '/제거 대상/{p=1} /후보 \(판단/{p=0} p' | grep -cE '^[0-9]')
  printf '  %-44s %d건\n' "$f" "$n"
  gate_total=$((gate_total + n))
done
echo "  합계 ${gate_total}건 (README에 적은 예외 ${EXPECTED_GATE}건)"
if [ "$gate_total" -gt "$EXPECTED_GATE" ]; then
  echo "  예외보다 많습니다. 새로 생긴 위반을 고치거나, 의도한 예외면 README 표에 적고 이 스크립트의 EXPECTED_GATE를 고치세요."
  fail=1
elif [ "$gate_total" -lt "$EXPECTED_GATE" ]; then
  echo "  예외보다 적습니다. 예외가 사라졌으면 README 표와 EXPECTED_GATE를 줄이세요."
  fail=1
fi

echo
echo "===== 2. 금지어를 자기 목소리로 쓴 곳 ====="
# SKILL.md 표 1열에서 금지어를 뽑는다. 활용하는 동사는 어간만 남겨
# '걸린다'가 '걸립니다', '걸려', '걸렸다'까지 잡히게 한다.
# bash 3.2(맥 기본)에는 mapfile이 없어서 파일로 받는다.
banned_file=$(mktemp)
trap 'rm -f "$banned_file"' EXIT
# 표는 금지어를 예시 구절로 적는다(`원칙에 걸린다`). 구절 전체로 찾으면
# 같은 말을 다르게 활용한 곳(`안 걸렸다고`)을 놓친다. 그래서 마지막 낱말만
# 꺼내고 어간을 남겨 활용형까지 잡는다.
grep '^| `' "$SKILL" |
  awk -F'|' '{print $2}' |
  grep -oE '`[^`]+`' | tr -d '`' |
  sed 's/([^)]*)//g; s/^ *//; s/ *$//' |
  awk '{print $NF}' |
  # 표가 괄호로 맥락을 한정한 말은 뺀다. `절`은 문법 용어일 때만, `화면`은 근거가
  # 페이지라고 부를 때만 금지다. 이 말들은 정상 쓰임이 많아 전부 잡으면 오탐이 된다.
  # `둘`과 `셋`은 아래 4번 검사가 조사와 함께 따로 확인한다.
  # 맥락 제한이 없는 말은 여기 넣지 않는다(`신호`는 표가 무조건 금지한다).
  # `어긋난다`는 표가 금지와 권장 양쪽에 쓴다. `값이 어긋난다`는 금지지만
  # `원칙에 어긋난다`는 규칙이 권장하는 표현이라, 낱말만으로는 가를 수 없다.
  grep -vE '^(줄|건|칸|판|절|둘|셋|머리|화면|상자|장면|시험|붙는다|읽는다|찾는다|끝남|기다림|하는 중|지지|서버|어긋난다)$' |
  grep -E '.{2,}' |
  sort -u > "$banned_file"

# 활용형을 만들어 목록에 더한다. 표는 기본형으로 적지만(`원칙에 걸린다`) 문서는
# 활용해 쓴다(`걸렸는데`, `걸립니다`). 어간만 남겨 찾으면 `걸`이 `걸음`까지
# 잡아 오탐이 된다. 그래서 어미를 붙여 활용형을 직접 만든다.
# bash 3.2(맥 기본)와 BSD sed는 한글 어간 분리를 못 해서 python으로 한다(실측).
python3 - "$banned_file" <<'PYEOF' >> "$banned_file"
import re, sys
ENDINGS = ['ㄴ다','는다','한다','난다','린다','운다','친다','긴다','된다']
SUFFIX = {
  '린다': ['렸', '려', '립니', '린', '리지', '리면'],
  '는다': ['았', '아', '습니', '은', '지 않', '으면'],
  '한다': ['했', '해', '합니', '한', '하지', '하면'],
  '친다': ['쳤', '쳐', '칩니', '친', '치지', '치면'],
  '긴다': ['겼', '겨', '깁니', '긴', '기지', '기면'],
  '운다': ['웠', '워', '웁니', '운', '우지', '우면'],
  '난다': ['났', '나', '납니', '난', '나지', '나면'],
  '된다': ['됐', '되어', '됩니', '된', '되지', '되면'],
  'ㄴ다': [],
}
out = set()
for line in open(sys.argv[1]):
    w = line.strip()
    m = re.match(r'(.+?)(' + '|'.join(ENDINGS) + r')$', w)
    if not m:
        continue
    stem, end = m.group(1), m.group(2)
    for suf in SUFFIX.get(end, []):
        out.add(stem + suf)
for w in sorted(out):
    print(w)
PYEOF
sort -u -o "$banned_file" "$banned_file"

# 판별법 2는 표가 아니라 산문에 금지어를 적는다(`축`(axis), `자리`(slot)).
# `(영어)`가 붙은 백틱 낱말을 그 줄에서 꺼낸다.
sed -n '/판별법 2 (영어 되짚기)/,/^$/p' "$SKILL" |
  grep -oE '`[^`]+`\([a-z-]+\)' |
  sed 's/`\([^`]*\)`.*/\1/' |
  grep -E '.{2,}' >> "$banned_file"
sort -u -o "$banned_file" "$banned_file"
echo "  SKILL.md 표에서 읽은 금지어 $(wc -l < "$banned_file" | tr -d ' ')개"

# 규칙이 예외로 정한 쓰임. 금지어가 들어 있어도 위반이 아니다.
#   빈자리  관용구
#   건물 기둥, 화면의 창, 동영상의 장면  글자 그대로의 뜻(원칙 2가 예외로 명시)
ALLOW='빈자리|건물 기둥|화면의 창|동영상의 장면|의견이 갈린다|마음이 흔들린다|화면 미러링'

hits=0
for f in "${DOCS[@]}"; do
  body=$(prose "$f")
  while IFS= read -r w; do
    [ -n "$w" ] || continue
    found=$(printf '%s\n' "$body" | grep -F "$w" | grep -vE "$ALLOW" | head -2)
    if [ -n "$found" ]; then
      printf '  %s  <- `%s`\n' "$f" "$w"
      printf '%s\n' "$found" | sed 's/^/    /' | cut -c1-110
      hits=$((hits+1))
    fi
  done < "$banned_file"
done
[ "$hits" = 0 ] && echo "  0건 (예외로 정한 쓰임은 빼고 셉니다)" || fail=1

echo
echo "===== 3. 원칙 7 형식 틀 ====="
tf=0
for f in "${DOCS[@]}"; do
  found=$(prose "$f" | grep -E '것이 아니다|것이다\.|것입니다\.|중요한 (것|점)은|핵심은 .*(다|니다)\.' | head -3)
  if [ -n "$found" ]; then
    printf '  %s\n' "$f"; printf '%s\n' "$found" | sed 's/^/    /' | cut -c1-120
    tf=$((tf+1))
  fi
done
[ "$tf" = 0 ] && echo "  0건" || fail=1

echo
echo "===== 4. 개수를 세는 맨 수사 ====="
nf=0
for f in "${DOCS[@]}"; do
  # '두 가지', '둘 중 하나'처럼 단위명사와 관용구는 규칙 범위가 아니다.
  found=$(prose "$f" |
    grep -oE '(둘|셋|넷|다섯|여섯|일곱|여덟|아홉)[ ]?(이면|이고|이다|입니다|을|를|은|는|만|과|와|씩)' |
    sort -u | head -5)
  if [ -n "$found" ]; then
    printf '  %s: %s\n' "$f" "$(printf '%s' "$found" | tr '\n' ' ')"
    nf=$((nf+1))
  fi
done
[ "$nf" = 0 ] && echo "  0건" || fail=1

echo
echo "===== 사람이 봐야 하는 것 (이 스크립트가 못 잡음) ====="
cat <<'NOTE'
  원칙 1  행위자 없는 피동. 피동이 문제인지는 맥락을 봐야 한다
  원칙 3  구체성. 수치가 있어야 할 자리인지 판단이 필요하다
  원칙 5  같은 개념 같은 말. 문서 전체를 비교해야 한다
  원칙 6  상투 서두와 결말
  원칙 8  읽는 사람이 모를 용어. 대상 독자를 알아야 한다
  판별법으로 새로 잡히는 표현. 목록에 없는 말이라 정규식으로 못 잡는다
NOTE

echo
if [ "$fail" = 0 ]; then
  echo "통과: 기계로 잡는 항목에 위반이 없습니다."
  exit 0
else
  echo "위반이 있습니다. 위 항목을 고치세요."
  exit 1
fi
