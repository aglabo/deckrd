#!/usr/bin/env bash
# project.spec.sh - ShellSpec tests for project.sh
#
# Copyright (c) 2025 atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

Include spec_helper.sh

SCRIPT="${SCRIPTS_DIR}/project.sh"

Describe "project.sh"

Before "setup_deckrd_tmpdir"
After "teardown_deckrd_tmpdir"

Describe "引数なしの場合"
It "エラーメッセージを出力してexit 1する"
When run bash "$SCRIPT"
The status should equal 1
The stderr should include "required"
End
End

Describe "--help オプション"
It "使い方を表示してexit 0する"
When run bash "$SCRIPT" --help
The status should equal 0
The output should include "Usage:"
End
End

Describe "不明なオプション"
It "エラーメッセージを出力してexit 1する"
When run bash "$SCRIPT" --project myapp --unknown
The status should equal 1
The output should include "Usage:"
The stderr should include "Unknown option"
End
End

Describe "予期しない位置引数"
It "エラーメッセージを出力してexit 1する"
When run bash "$SCRIPT" --project myapp unexpected
The status should equal 1
The output should include "Usage:"
The stderr should include "Unexpected argument"
End
End

Describe "正常系"
It "exit 0する"
When run bash "$SCRIPT" --project myapp --language go
The status should equal 0
The output should include "myapp"
End

It "project が出力に含まれる"
When run bash "$SCRIPT" --project myapp --language go
The output should include "myapp"
End

It "language が出力に含まれる"
When run bash "$SCRIPT" --project myapp --language go
The output should include "go"
End

It "結果サマリーを出力する"
When run bash "$SCRIPT" --project myapp --language typescript
The output should include "myapp"
The output should include "typescript"
End
End

Describe "--language オプション"
It "typescript を指定できる"
When run bash "$SCRIPT" --project myapp --language typescript
The status should equal 0
The output should include "typescript"
End

It "python を指定できる"
When run bash "$SCRIPT" --project myapp --language python
The status should equal 0
The output should include "python"
End

It "rust を指定できる"
When run bash "$SCRIPT" --project myapp --language rust
The status should equal 0
The output should include "rust"
End

It "サポート外の言語はexit 1する"
When run bash "$SCRIPT" --project myapp --language cobol
The status should equal 1
The stderr should include "Unsupported language"
End
End

Describe "--lang エイリアス"
It "--lang でも言語を指定できる"
When run bash "$SCRIPT" --project myapp --lang go
The status should equal 0
The output should include "go"
End
End

Describe "--project-type オプション"
It "project_type が出力に含まれる"
When run bash "$SCRIPT" --project myapp --project-type webapp
The output should include "webapp"
End
End

Describe "--ai-model オプション"
It "指定したモデルが出力に含まれる"
When run bash "$SCRIPT" --project myapp --ai-model claude-sonnet-4-5
The output should include "claude-sonnet-4-5"
End
End

Describe "既存の project.json の更新"
Before "setup_existing_project"
setup_existing_project() {
  mkdir -p "$DECKRD_LOCAL"
  cat >"${DECKRD_LOCAL}/project.json" <<'JSON'
{
  "project": "oldapp",
  "language": "go",
  "created_at": "2025-01-01T00:00:00Z",
  "updated_at": "2025-01-01T00:00:00Z"
}
JSON
}

It "exit 0する"
When run bash "$SCRIPT" --project newapp --language typescript
The status should equal 0
The output should include "newapp"
End
End

End
