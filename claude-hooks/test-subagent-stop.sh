#!/usr/bin/env bash
# subagent-stop.sh 동작 검사. 가짜 서브에이전트 기록으로 각 경우를 확인한다.
cd "$(dirname "$0")" || exit 1
hook="$PWD/subagent-stop.sh"
d=$(mktemp -d); trap 'rm -rf "$d"' EXIT
fail=0
tr_=$d/t.jsonl
# use <도구> <입력 JSON>: 기록 한 줄을 만든다
use() { jq -nc --arg n "$1" --argjson i "$2" '{type:"assistant",message:{content:[{type:"tool_use",name:$n,input:$i}]}}'; }
run() { jq -nc --argjson a "${1:-false}" --arg p "$tr_" '{stop_hook_active:$a,agent_transcript_path:$p}' | bash "$hook"; }
chk() { # 이름, 출력, 기대(block|none), 포함할 글, 빠져야 할 글
  local ok=1
  if [ "$3" = block ]; then jq -e '.decision=="block"' <<<"$2" >/dev/null 2>&1 || ok=0
  else [ -z "$2" ] || ok=0; fi
  [ -z "$4" ] || grep -qF -- "$4" <<<"$2" || ok=0
  [ -z "$5" ] || ! grep -qF -- "$5" <<<"$2" || ok=0
  if [ $ok = 1 ]; then echo "PASS $1"; else echo "FAIL $1: $2"; fail=1; fi
}
w() { printf '%s' "$2" > "$1"; use Write "$(jq -nc --arg f "$1" --arg c "$2" '{file_path:$f,content:$c}')" > "$tr_"; }

w "$d/a.md" $'사실·수치를 적는다.\n'; chk a "$(run)" block "사실·수치를 적는다."
w "$d/a.md" $'사실·수치를 적는다.\n'; chk b "$(run true)" none
printf '가—나 문장이다.\n기존 줄이다.\n' > $d/c.md
use Edit "$(jq -nc --arg f $d/c.md '{file_path:$f,old_string:"기존 줄이다.",new_string:"새 문장을 넣었다."}')" > "$tr_"
printf '가—나 문장이다.\n새 문장을 넣었다.\n' > $d/c.md; chk c "$(run)" none
printf '가—나 문장이다.\nA·B 문장을 넣었다.\n' > $d/d.md
use Edit "$(jq -nc --arg f $d/d.md '{file_path:$f,old_string:"x",new_string:"A·B 문장을 넣었다."}')" > "$tr_"
chk d "$(run)" block "A·B 문장을 넣었다." "가—나"
printf '제목\nC·D 항목이다.\n' > $d/e.md
use MultiEdit "$(jq -nc --arg f $d/e.md '{file_path:$f,edits:[{old_string:"x",new_string:"C·D 항목이다."}]}')" > "$tr_"
chk e "$(run)" block "C·D 항목이다."
printf 'a — b\n' > $d/f.md; w $d/f.md $'a — b\n'; chk f "$(run)" none
printf '점검 범위 — 서버·저장소를 본다.\n문의는 운영 채널로 보낸다.\n' > $d/k.md
use Edit "$(jq -nc --arg f $d/k.md '{file_path:$f,old_string:"점검 범위 — 서버·저장소를 본다.\n",new_string:"점검 범위 — 서버·저장소를 본다.\n문의는 운영 채널로 보낸다.\n"}')" > "$tr_"
chk k "$(run)" none
w $d/g.md $'`x` 값과 사실·수치를 본다.\n'; printf '`x` 값과 사실·수치를 본다.\n' > $d/g.md
chk g "$(run)" block "사실·수치를 본다."
printf '// 사실·수치\n' > $d/h.ts; w $d/h.ts $'// 사실·수치\n'; chk h "$(run)" none
mkdir "$d/a b"; w "$d/a b/i.md" $'사실·수치를 적는다.\n'; printf '사실·수치를 적는다.\n' > "$d/a b/i.md"
chk i "$(run)" block "사실·수치를 적는다."
w $d/a.md $'사실·수치를 적는다.\n'; o=$(PATH=/var/empty /bin/bash "$hook" </dev/null 2>&1); rc=$?
if [ -z "$o" ] && [ $rc = 0 ]; then echo "PASS j"; else echo "FAIL j: rc=$rc $o"; fail=1; fi
exit $fail
