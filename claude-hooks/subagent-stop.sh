#!/usr/bin/env bash
# 서브에이전트가 끝날 때 실행한다. 그 서브에이전트가 Write, Edit, MultiEdit로
# 저장한 한글 문서를 scan.sh로 검사하고, 서브에이전트가 직접 쓴 줄에 제거
# 대상이 남아 있으면 한 번 되돌려 보내 고치게 한다. 두 번째 종료는 통과시킨다.
# jq가 없거나 기록을 읽지 못하면 검사하지 않고 통과시킨다.

command -v jq >/dev/null 2>&1 || exit 0
in=$(cat)
[ "$(jq -r '.stop_hook_active // false' <<<"$in" 2>/dev/null)" = false ] || exit 0
t=$(jq -r '.agent_transcript_path // empty' <<<"$in" 2>/dev/null)
[ -f "$t" ] || exit 0

# scan.sh의 한글 정규식은 UTF-8 로캘에서만 글자 단위로 맞는다
case "${LC_ALL:-${LC_CTYPE:-${LANG:-}}}" in
  *[Uu][Tt][Ff]-8* | *[Uu][Tt][Ff]8*) ;;
  *) l=$(locale -a 2>/dev/null | grep -iE '^(C|en_US)\.utf-?8$' | head -1)
     [ -n "$l" ] && export LC_ALL="$l" ;;
esac

scan="$(dirname "$0")/../skills/technical-writing-ko/scan.sh"
written=$(mktemp) || exit 0
trap 'rm -f "$written"' EXIT

edits='select(.type == "assistant") | .message.content[]?
  | select(.type == "tool_use" and (.name == "Write" or .name == "Edit" or .name == "MultiEdit"))'

msg=
while IFS= read -r f; do
  [ -f "$f" ] || continue
  perl -CSD -0777 -ne 'exit(/\p{Hangul}/ ? 0 : 1)' "$f" 2>/dev/null || continue
  # 이 서브에이전트가 이 파일에 쓴 글. Write는 내용 전체, Edit는 old_string에 없던 줄만 센다
  jq -r --arg f "$f" "$edits"' | select(.input.file_path == $f)
    | (.input.content | strings),
      ((.input.edits // [.input])[] | select(.new_string | type == "string")
        | ((.new_string | split("\n")) - ((.old_string // "") | split("\n")))[])' "$t" > "$written"
  out=$(bash "$scan" "$f" 2>/dev/null); [ $? -eq 1 ] || continue
  # scan.sh는 백틱 안을 지운 줄을 출력하므로 줄 번호로 원문 줄을 다시 읽어 대조한다
  hits=$(printf '%s\n' "$out" | awk -F'\t' '
    /^===== 후보/ { exit }
    /^--- / { c = $0; gsub(/^--- | ---$/, "", c); next }
    /^[0-9]+\t/ { print $1 "\t" c }' |
    while IFS=$'\t' read -r n c; do
      line=$(sed -n "${n}p" "$f")
      grep -qxF -- "$line" "$written" && printf '%s번 줄 (%s): %s\n' "$n" "$c" "$line"
    done | head -40)
  [ -n "$hits" ] && msg+=$'\n\n'"$f"$'\n'"$hits"
done < <(jq -r "$edits"' | .input.file_path // empty' "$t" 2>/dev/null |
  grep -iE '\.(md|mdx|markdown|txt|html?)$' | sort -u)

[ -n "$msg" ] || exit 0
jq -n --arg r "저장한 한글 문서에서 직접 쓴 줄에 technical-writing-ko 제거 대상이 남아 있습니다. technical-writing-ko 스킬 규칙대로 고치고 scan.sh로 다시 확인한 뒤 끝내세요. 직접 인용한 원문은 고치지 말고, 그대로 둔 줄은 이유를 최종 답에 적으세요.$msg" \
  '{decision: "block", reason: $r}'
