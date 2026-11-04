# 설치

스킬만 설치하거나 Claude Code 또는 Codex 플러그인으로 설치할 수 있습니다.
Claude Code에서 문체 규칙을 항상 켜두려면 플러그인을 설치한 뒤 `Korean Plain`을 선택합니다.

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

목록에서 `Korean Plain`을 고르면 이번 세션에 바로 적용됩니다.
항상 켜두려면 `~/.claude/settings.json`에 넣습니다.

```json
{ "outputStyle": "Korean Plain" }
```

되돌릴 때는 `/output-style`에서 `Default`를 고릅니다.

## 3. Codex 플러그인으로 설치

`codex plugin add`를 지원하는 Codex CLI가 필요합니다. 다음 명령으로 지원 여부를 확인합니다.

```bash
codex plugin add --help
```

### 로컬 저장소에서 설치

저장소를 내려받은 폴더에서 실행합니다.

```bash
codex plugin marketplace add .
codex plugin add technical-writing-ko@technical-writing-ko
codex plugin list --marketplace technical-writing-ko --json
```

설치 후 Codex 앱을 다시 열고 새 대화를 시작합니다.
플러그인 목록에서 `Technical Writing KO`를 확인하고 문서 작성을 요청합니다.

```text
technical-writing-ko 스킬로 이 문서를 다듬어줘
```

`plugin.json`은 플러그인 정보와 표시 이름을 정의합니다.
`.agents/plugins/marketplace.json`은 설치할 플러그인의 위치를 정의합니다.
플러그인은 `skills/technical-writing-ko/`의 기존 스킬과 검사 스크립트를 사용합니다.
스킬 단독 설치와 문서 작성 기능은 같으며, `Korean Plain` 출력 문체는 Claude Code 전용입니다.

### GitHub에서 설치

로컬 저장소 없이 설치할 수 있습니다.

```bash
codex plugin marketplace add joshyeom/technical-writing-ko
codex plugin add technical-writing-ko@technical-writing-ko
```

이 방식은 해당 저장소를 플러그인 설치 출처로 등록합니다.
공개 플러그인 디렉터리에 노출하려면 OpenAI에 별도로 제출해야 합니다.

### 파일을 수정한 뒤

로컬 저장소에서 수정했다면 같은 플러그인을 다시 설치하고 Codex 앱을 다시 엽니다.
GitHub에서 설치했다면 마켓플레이스도 먼저 갱신합니다.

```bash
codex plugin marketplace upgrade technical-writing-ko
codex plugin add technical-writing-ko@technical-writing-ko
```

형식과 배포 방식은 [OpenAI 플러그인 문서](https://developers.openai.com/plugins/build/plugins)를 따릅니다.

## 4. 출력 문체만 쓰고 싶을 때

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
