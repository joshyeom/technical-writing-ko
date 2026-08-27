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
| 언제 | 부를 때만 | 항상 |
| 대상 | 파일로 저장하는 문서 | 채팅 답변 |
| 범위 | 문체 4단 결정, 기계 스캔, 원칙 리뷰, 재검증 게이트 | 문자와 어법만 |
| 서식 | 합쇼체로 쓰고 표는 개조식으로 분리 | 안 건드림 |

출력 문체는 답변 길이나 불릿 서식을 바꾸지 않습니다. 줄표, 이중피동, 번역투,
은유 술어만 걷어냅니다.
