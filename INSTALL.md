# 설치

두 가지 경로가 있습니다. 스킬만 필요하면 첫 번째, Claude Code에서 문체 규칙까지
항상 켜두고 싶으면 두 번째입니다.

## 1. 스킬로 설치

77개 코딩 에이전트를 지원합니다. Claude Code, OpenCode, Cursor, Codex, Gemini CLI 등.

```bash
npx skills add joshyeom/technical-writing-ko
```

### 에이전트를 지정할 때

```bash
npx skills add joshyeom/technical-writing-ko -a claude-code
npx skills add joshyeom/technical-writing-ko -a opencode
npx skills add joshyeom/technical-writing-ko -a cursor
npx skills add joshyeom/technical-writing-ko -a codex
npx skills add joshyeom/technical-writing-ko -a gemini-cli
```

여러 개를 한 번에 지정할 수 있습니다.

```bash
npx skills add joshyeom/technical-writing-ko -a claude-code -a cursor -a codex
```

### 설치 위치

```bash
npx skills add joshyeom/technical-writing-ko -g      # 전역 (~/.claude/skills/)
npx skills add joshyeom/technical-writing-ko         # 프로젝트 (./.claude/skills/)
```

전역은 모든 프로젝트에서 쓰고, 프로젝트는 팀과 함께 커밋합니다.

### 설치 없이 한 번만

```bash
npx skills use joshyeom/technical-writing-ko@technical-writing-ko | claude
```

### 비대화 설치

```bash
npx skills add joshyeom/technical-writing-ko -g -a claude-code -y
```

### 관리

```bash
npx skills list                                   # 설치된 것 확인
npx skills update technical-writing-ko                 # 갱신
npx skills remove technical-writing-ko                 # 삭제
```

## 2. Claude Code 플러그인으로 설치

스킬에 더해 출력 문체(output style)까지 함께 들어옵니다. Claude Code 전용입니다.

```
/plugin marketplace add joshyeom/technical-writing-ko
/plugin install technical-writing-ko
```

### 출력 문체 켜기

플러그인을 설치하면 `Korean Plain` 문체가 목록에 뜹니다.

```
/output-style
```

목록에서 `Korean Plain`을 고르면 이번 세션에 바로 걸립니다.
항상 켜두려면 `~/.claude/settings.json`에 넣습니다.

```json
{ "outputStyle": "Korean Plain" }
```

되돌릴 때는 `/output-style`에서 `Default`를 고릅니다.

## 3. 출력 문체만 쓰고 싶을 때

플러그인 없이 파일 하나만 옮겨도 됩니다.

```bash
mkdir -p ~/.claude/output-styles
curl -sL https://raw.githubusercontent.com/joshyeom/technical-writing-ko/main/output-styles/korean-plain.md \
  -o ~/.claude/output-styles/korean-plain.md
```

그다음 `/output-style`에서 고릅니다.

## 스킬과 출력 문체의 차이

| | 스킬 | 출력 문체 |
|---|---|---|
| 언제 | 부를 때만 | `Korean Plain`을 켠 동안 모든 한글 답변 |
| 대상 | 파일로 저장하는 문서. 부르면 채팅 답변도 | 채팅 답변 |
| 범위 | 파일 문서는 문체 4단 결정, 정규식 검사, 원칙 1~8과 문장 순서 검토, 재검증. 채팅은 임시 파일로 정규식 검사를 하고 보내기 전 확인 순서 적용 | 제거 대상 확인, 원칙 1~8과 문장 순서 검토, 제거 대상과 의미 보존 재확인 |
| 서식 | 파일 문서는 문체 4단 결정과 위치별 서식 적용. 채팅은 기존 서식 유지 | 불릿, 짧은 줄, 표, 제목 유지 |

채팅 답변은 문장과 메시지 하나나 항목 하나 안의 문장 순서를 다듬습니다. 사용자가 어미를 따로 지정하지 않으면 기존 어미를 유지하며, 파일 문서의 개조식 규칙은 적용하지 않습니다.

출력 문체로 쓰는 채팅 답변에서는 스크립트를 실행하지 않습니다. 스킬을 불러 채팅 답변을 다듬으면 임시 파일에 저장해 정규식 검사를 합니다. 보내기 전에 제거 대상을 확인하고, 은유 술어와 독자가 모를 말을 먼저 검토합니다. 나머지 원칙과 문장 순서를 확인한 뒤 제거 대상과 의미 보존을 다시 확인합니다. 스캔 건수는 보고하지 않으며, 근거에서 알 수 없는 내용은 `미해결`로 밝힙니다.
