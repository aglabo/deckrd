#!/usr/bin/env bash
# ai-runner.spec.sh - ShellSpec tests for scripts/lib/ai-runner.sh
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

Include spec_helper.sh

SCRIPT="${DECKRD_LIB_DIR}/ai-runner.sh"

Describe "ai-runner.sh"

  Describe "source 可能であること"
    It "exit 0 で source できる"
      When run bash -c ". \"$SCRIPT\" && echo ok"
      The status should equal 0
      The output should equal "ok"
    End
  End

  Describe "二重 source の冪等性"
    It "二重 source しても resolve_ai_cli が存在する"
      When run bash -c ". \"$SCRIPT\" && . \"$SCRIPT\" && declare -f resolve_ai_cli > /dev/null && echo ok"
      The status should equal 0
      The output should equal "ok"
    End

    It "二重 source しても run_ai が存在する"
      When run bash -c ". \"$SCRIPT\" && . \"$SCRIPT\" && declare -f run_ai > /dev/null && echo ok"
      The status should equal 0
      The output should equal "ok"
    End
  End

  Describe "resolve_ai_cli"

    Describe "anthropic系モデル"
      It "anthropic/claude-3-5 -> claude"
        When run bash -c ". \"$SCRIPT\" && resolve_ai_cli 'anthropic/claude-3-5'"
        The status should equal 0
        The output should equal "claude"
      End

      It "claude-3-opus -> claude"
        When run bash -c ". \"$SCRIPT\" && resolve_ai_cli 'claude-3-opus'"
        The status should equal 0
        The output should equal "claude"
      End
    End

    Describe "claude短縮エイリアス"
      It "sonnet -> claude"
        When run bash -c ". \"$SCRIPT\" && resolve_ai_cli 'sonnet'"
        The status should equal 0
        The output should equal "claude"
      End

      It "opus -> claude"
        When run bash -c ". \"$SCRIPT\" && resolve_ai_cli 'opus'"
        The status should equal 0
        The output should equal "claude"
      End

      It "haiku -> claude"
        When run bash -c ". \"$SCRIPT\" && resolve_ai_cli 'haiku'"
        The status should equal 0
        The output should equal "claude"
      End

      It "sonnet-1m -> claude"
        When run bash -c ". \"$SCRIPT\" && resolve_ai_cli 'sonnet-1m'"
        The status should equal 0
        The output should equal "claude"
      End

      It "opusplan -> claude"
        When run bash -c ". \"$SCRIPT\" && resolve_ai_cli 'opusplan'"
        The status should equal 0
        The output should equal "claude"
      End
    End

    Describe "openai系モデル"
      It "openai/gpt-4o -> codex"
        When run bash -c ". \"$SCRIPT\" && resolve_ai_cli 'openai/gpt-4o'"
        The status should equal 0
        The output should equal "codex"
      End

      It "gpt-4-turbo -> codex"
        When run bash -c ". \"$SCRIPT\" && resolve_ai_cli 'gpt-4-turbo'"
        The status should equal 0
        The output should equal "codex"
      End

      It "o1-preview -> codex"
        When run bash -c ". \"$SCRIPT\" && resolve_ai_cli 'o1-preview'"
        The status should equal 0
        The output should equal "codex"
      End

      It "o3-mini -> codex"
        When run bash -c ". \"$SCRIPT\" && resolve_ai_cli 'o3-mini'"
        The status should equal 0
        The output should equal "codex"
      End
    End

    Describe "google系モデル"
      It "google/gemini-2.0 -> gemini"
        When run bash -c ". \"$SCRIPT\" && resolve_ai_cli 'google/gemini-2.0'"
        The status should equal 0
        The output should equal "gemini"
      End

      It "gemini-1.5-pro -> gemini"
        When run bash -c ". \"$SCRIPT\" && resolve_ai_cli 'gemini-1.5-pro'"
        The status should equal 0
        The output should equal "gemini"
      End

      It "googleai/gemini-3 -> gemini"
        When run bash -c ". \"$SCRIPT\" && resolve_ai_cli 'googleai/gemini-3'"
        The status should equal 0
        The output should equal "gemini"
      End

      It "googleai/gemini-2.5 -> gemini"
        When run bash -c ". \"$SCRIPT\" && resolve_ai_cli 'googleai/gemini-2.5'"
        The status should equal 0
        The output should equal "gemini"
      End
    End

    Describe "github系モデル"
      It "github/gpt-4.1 -> copilot"
        When run bash -c ". \"$SCRIPT\" && resolve_ai_cli 'github/gpt-4.1'"
        The status should equal 0
        The output should equal "copilot"
      End

      It "github-copilot/gpt-5 -> copilot"
        When run bash -c ". \"$SCRIPT\" && resolve_ai_cli 'github-copilot/gpt-5'"
        The status should equal 0
        The output should equal "copilot"
      End

      It "github-copilot/claude-sonnet-4.6 -> copilot"
        When run bash -c ". \"$SCRIPT\" && resolve_ai_cli 'github-copilot/claude-sonnet-4.6'"
        The status should equal 0
        The output should equal "copilot"
      End

      It "github-copilot/grok-code-fast-1 -> copilot"
        When run bash -c ". \"$SCRIPT\" && resolve_ai_cli 'github-copilot/grok-code-fast-1'"
        The status should equal 0
        The output should equal "copilot"
      End

      It "copilot/gpt-4.1 -> copilot"
        When run bash -c ". \"$SCRIPT\" && resolve_ai_cli 'copilot/gpt-4.1'"
        The status should equal 0
        The output should equal "copilot"
      End
    End

    Describe "opencode系モデル"
      It "opencode/gpt-5 -> opencode"
        When run bash -c ". \"$SCRIPT\" && resolve_ai_cli 'opencode/gpt-5'"
        The status should equal 0
        The output should equal "opencode"
      End

      It "opencode/claude-sonnet-4-6 -> opencode"
        When run bash -c ". \"$SCRIPT\" && resolve_ai_cli 'opencode/claude-sonnet-4-6'"
        The status should equal 0
        The output should equal "opencode"
      End

      It "opencode/big-pickle -> opencode"
        When run bash -c ". \"$SCRIPT\" && resolve_ai_cli 'opencode/big-pickle'"
        The status should equal 0
        The output should equal "opencode"
      End
    End

    Describe "エラーケース"
      It "未知モデルは return 1"
        When run bash -c ". \"$SCRIPT\" && resolve_ai_cli 'unknown/model'; echo \$?"
        The output should equal "1"
      End

      It "引数なしは return 1"
        When run bash -c ". \"$SCRIPT\" && resolve_ai_cli; echo \$?"
        The output should equal "1"
      End

      It "空文字列は return 1"
        When run bash -c ". \"$SCRIPT\" && resolve_ai_cli ''; echo \$?"
        The output should equal "1"
      End
    End

    Describe "エッジケース: org/ のみ"
      It "anthropic/ -> claude (bash glob * は空文字にもマッチ)"
        When run bash -c ". \"$SCRIPT\" && resolve_ai_cli 'anthropic/'"
        The status should equal 0
        The output should equal "claude"
      End

      It "openai/ -> codex"
        When run bash -c ". \"$SCRIPT\" && resolve_ai_cli 'openai/'"
        The status should equal 0
        The output should equal "codex"
      End

      It "opencode/ -> opencode"
        When run bash -c ". \"$SCRIPT\" && resolve_ai_cli 'opencode/'"
        The status should equal 0
        The output should equal "opencode"
      End

      It "copilot/ -> copilot"
        When run bash -c ". \"$SCRIPT\" && resolve_ai_cli 'copilot/'"
        The status should equal 0
        The output should equal "copilot"
      End
    End

    Describe "エッジケース: ハイフン後が空"
      It "claude- -> claude (bash glob * は空文字にもマッチ)"
        When run bash -c ". \"$SCRIPT\" && resolve_ai_cli 'claude-'"
        The status should equal 0
        The output should equal "claude"
      End

      It "o1- -> codex"
        When run bash -c ". \"$SCRIPT\" && resolve_ai_cli 'o1-'"
        The status should equal 0
        The output should equal "codex"
      End
    End

    Describe "エッジケース: 偽陽性候補"
      It "anthropic (スラッシュなし) -> exit=1"
        When run bash -c ". \"$SCRIPT\" && resolve_ai_cli 'anthropic'; echo \$?"
        The output should equal "1"
      End

      It "anthropic-fake -> exit=1"
        When run bash -c ". \"$SCRIPT\" && resolve_ai_cli 'anthropic-fake'; echo \$?"
        The output should equal "1"
      End

      It "opencode-something -> exit=1"
        When run bash -c ". \"$SCRIPT\" && resolve_ai_cli 'opencode-something'; echo \$?"
        The output should equal "1"
      End

      It "github-something/model -> exit=1"
        When run bash -c ". \"$SCRIPT\" && resolve_ai_cli 'github-something/model'; echo \$?"
        The output should equal "1"
      End

      It "o3 (ハイフンなし) -> exit=1"
        When run bash -c ". \"$SCRIPT\" && resolve_ai_cli 'o3'; echo \$?"
        The output should equal "1"
      End

      It "copilot (スラッシュなし) -> exit=1"
        When run bash -c ". \"$SCRIPT\" && resolve_ai_cli 'copilot'; echo \$?"
        The output should equal "1"
      End

      It "gpt (ハイフンなし) -> exit=1"
        When run bash -c ". \"$SCRIPT\" && resolve_ai_cli 'gpt'; echo \$?"
        The output should equal "1"
      End

      It "gemini (ハイフンなし) -> exit=1"
        When run bash -c ". \"$SCRIPT\" && resolve_ai_cli 'gemini'; echo \$?"
        The output should equal "1"
      End
    End

    Describe "エッジケース: 特殊文字"
      It "claude-3 5 (スペース含む) -> claude (bash glob は通す)"
        When run bash -c ". \"$SCRIPT\" && resolve_ai_cli 'claude-3 5'"
        The status should equal 0
        The output should equal "claude"
      End

      It "gpt-4;echo hacked (セミコロン) -> codex (インジェクション不可)"
        When run bash -c ". \"$SCRIPT\" && resolve_ai_cli 'gpt-4;echo hacked'"
        The status should equal 0
        The output should equal "codex"
      End
    End

    Describe "エッジケース: 数字のみ・その他"
      It "12345 -> exit=1"
        When run bash -c ". \"$SCRIPT\" && resolve_ai_cli '12345'; echo \$?"
        The output should equal "1"
      End

      It "default -> claude (エイリアス)"
        When run bash -c ". \"$SCRIPT\" && resolve_ai_cli 'default'"
        The status should equal 0
        The output should equal "claude"
      End
    End

  End

  Describe "run_ai"

    Describe "エラーケース"
      It "モデル引数なしは return 1"
        When run bash -c ". \"$SCRIPT\" && echo 'hello' | run_ai"
        The output should equal "1"
        The error should include "model is required"
      End

      It "未知モデルは return 1"
        When run bash -c ". \"$SCRIPT\" && echo 'hello' | run_ai 'unknown/model'"
        The output should equal "1"
        The error should include "unknown model"
      End

      It "CLIが存在しない場合は return 2"
        When run bash -c "
          . \"$SCRIPT\"
          export PATH=/nonexistent
          echo 'hello' | run_ai 'claude-3-opus'
        "
        The output should equal "2"
        The error should include "CLI not found"
      End

      It "タイムアウト時は return 124、stderr にエラー理由、stdout に 124 を出す"
        When run bash -c "
          . \"$SCRIPT\"
          MOCK_BIN=\"\$(mktemp -d)\"
          cat > \"\$MOCK_BIN/claude\" <<'MOCK'
#!/usr/bin/env bash
sleep 10
MOCK
          chmod +x \"\$MOCK_BIN/claude\"
          export PATH=\"\$MOCK_BIN:\$PATH\"
          echo 'hello' | run_ai 'sonnet' 1
          rm -rf \"\$MOCK_BIN\"
        "
        The output should equal "124"
        The error should include "timeout"
      End
    End

    Describe "正常系 (モックCLI使用)"
      # モックは stdin を読まず引数のみ出力する (ハング防止)
      It "claude モデルで claude コマンドを実行する"
        When run bash -c "
          MOCK_BIN=\"\$(mktemp -d)\"
          printf '#!/usr/bin/env bash\necho \"MOCK_CLAUDE:\$*\"\n' > \"\$MOCK_BIN/claude\"
          chmod +x \"\$MOCK_BIN/claude\"
          export PATH=\"\$MOCK_BIN:\$PATH\"
          . \"$SCRIPT\"
          echo 'hello' | run_ai 'claude-3-opus'
          rm -rf \"\$MOCK_BIN\"
        "
        The status should equal 0
        The output should include "MOCK_CLAUDE:"
        The output should include "--model"
        The output should include "claude-3-opus"
      End

      It "openai モデルで codex exec コマンドを実行する"
        When run bash -c "
          MOCK_BIN=\"\$(mktemp -d)\"
          printf '#!/usr/bin/env bash\necho \"MOCK_CODEX:\$*\"\n' > \"\$MOCK_BIN/codex\"
          chmod +x \"\$MOCK_BIN/codex\"
          export PATH=\"\$MOCK_BIN:\$PATH\"
          . \"$SCRIPT\"
          echo 'hello' | run_ai 'openai/gpt-4o'
          rm -rf \"\$MOCK_BIN\"
        "
        The status should equal 0
        The output should include "MOCK_CODEX:"
        The output should include "exec"
        The output should include "--model"
        The output should include "openai/gpt-4o"
      End

      It "google モデルで gemini コマンドを実行する"
        When run bash -c "
          MOCK_BIN=\"\$(mktemp -d)\"
          printf '#!/usr/bin/env bash\necho \"MOCK_GEMINI:\$*\"\n' > \"\$MOCK_BIN/gemini\"
          chmod +x \"\$MOCK_BIN/gemini\"
          export PATH=\"\$MOCK_BIN:\$PATH\"
          . \"$SCRIPT\"
          echo 'hello' | run_ai 'google/gemini-2.0'
          rm -rf \"\$MOCK_BIN\"
        "
        The status should equal 0
        The output should include "MOCK_GEMINI:"
        The output should include "--model"
        The output should include "google/gemini-2.0"
      End

      It "copilot モデルで --model を渡して copilot コマンドを実行する"
        When run bash -c "
          MOCK_BIN=\"\$(mktemp -d)\"
          printf '#!/usr/bin/env bash\necho \"MOCK_COPILOT:\$*\"\n' > \"\$MOCK_BIN/copilot\"
          chmod +x \"\$MOCK_BIN/copilot\"
          export PATH=\"\$MOCK_BIN:\$PATH\"
          . \"$SCRIPT\"
          echo 'hello' | run_ai 'github/gpt-4.1'
          rm -rf \"\$MOCK_BIN\"
        "
        The status should equal 0
        The output should include "MOCK_COPILOT:"
        The output should include "suggest"
        The output should include "--model"
        The output should include "gpt-4.1"
      End

      It "copilot 非対応モデルは return 1"
        When run bash -c "
          MOCK_BIN=\"\$(mktemp -d)\"
          printf '#!/usr/bin/env bash\necho \"MOCK_COPILOT:\$*\"\n' > \"\$MOCK_BIN/copilot\"
          chmod +x \"\$MOCK_BIN/copilot\"
          export PATH=\"\$MOCK_BIN:\$PATH\"
          . \"$SCRIPT\"
          echo 'hello' | run_ai 'copilot/unknown-model'
          rm -rf \"\$MOCK_BIN\"
        "
        The output should equal "1"
        The error should include "unsupported model"
      End

      It "opencode モデルで opencode コマンドを実行する"
        When run bash -c "
          MOCK_BIN=\"\$(mktemp -d)\"
          printf '#!/usr/bin/env bash\necho \"MOCK_OPENCODE:\$*\"\n' > \"\$MOCK_BIN/opencode\"
          chmod +x \"\$MOCK_BIN/opencode\"
          export PATH=\"\$MOCK_BIN:\$PATH\"
          . \"$SCRIPT\"
          echo 'hello' | run_ai 'opencode/gpt-5'
          rm -rf \"\$MOCK_BIN\"
        "
        The status should equal 0
        The output should include "MOCK_OPENCODE:"
        The output should include "run"
        The output should include "--model"
        The output should include "opencode/gpt-5"
      End

      It "sonnet エイリアスをそのまま --model sonnet で渡す"
        When run bash -c "
          MOCK_BIN=\"\$(mktemp -d)\"
          printf '#!/usr/bin/env bash\necho \"MOCK_CLAUDE:\$*\"\n' > \"\$MOCK_BIN/claude\"
          chmod +x \"\$MOCK_BIN/claude\"
          export PATH=\"\$MOCK_BIN:\$PATH\"
          . \"$SCRIPT\"
          echo 'hello' | run_ai 'sonnet'
          rm -rf \"\$MOCK_BIN\"
        "
        The status should equal 0
        The output should include "MOCK_CLAUDE:"
        The output should include "--model"
        The output should include "sonnet"
      End

      It "opus エイリアスをそのまま --model opus で渡す"
        When run bash -c "
          MOCK_BIN=\"\$(mktemp -d)\"
          printf '#!/usr/bin/env bash\necho \"MOCK_CLAUDE:\$*\"\n' > \"\$MOCK_BIN/claude\"
          chmod +x \"\$MOCK_BIN/claude\"
          export PATH=\"\$MOCK_BIN:\$PATH\"
          . \"$SCRIPT\"
          echo 'hello' | run_ai 'opus'
          rm -rf \"\$MOCK_BIN\"
        "
        The status should equal 0
        The output should include "MOCK_CLAUDE:"
        The output should include "--model"
        The output should include "opus"
      End

      It "haiku エイリアスをそのまま --model haiku で渡す"
        When run bash -c "
          MOCK_BIN=\"\$(mktemp -d)\"
          printf '#!/usr/bin/env bash\necho \"MOCK_CLAUDE:\$*\"\n' > \"\$MOCK_BIN/claude\"
          chmod +x \"\$MOCK_BIN/claude\"
          export PATH=\"\$MOCK_BIN:\$PATH\"
          . \"$SCRIPT\"
          echo 'hello' | run_ai 'haiku'
          rm -rf \"\$MOCK_BIN\"
        "
        The status should equal 0
        The output should include "MOCK_CLAUDE:"
        The output should include "--model"
        The output should include "haiku"
      End

      It "sonnet-1m エイリアスで --model sonnet と --context-window 1000000 を渡す"
        When run bash -c "
          MOCK_BIN=\"\$(mktemp -d)\"
          printf '#!/usr/bin/env bash\necho \"MOCK_CLAUDE:\$*\"\n' > \"\$MOCK_BIN/claude\"
          chmod +x \"\$MOCK_BIN/claude\"
          export PATH=\"\$MOCK_BIN:\$PATH\"
          . \"$SCRIPT\"
          echo 'hello' | run_ai 'sonnet-1m'
          rm -rf \"\$MOCK_BIN\"
        "
        The status should equal 0
        The output should include "MOCK_CLAUDE:"
        The output should include "--model"
        The output should include "sonnet"
        The output should include "--context-window"
        The output should include "1000000"
      End

      It "完全モデル名 claude-sonnet-4-6 をそのまま渡す"
        When run bash -c "
          MOCK_BIN=\"\$(mktemp -d)\"
          printf '#!/usr/bin/env bash\necho \"MOCK_CLAUDE:\$*\"\n' > \"\$MOCK_BIN/claude\"
          chmod +x \"\$MOCK_BIN/claude\"
          export PATH=\"\$MOCK_BIN:\$PATH\"
          . \"$SCRIPT\"
          echo 'hello' | run_ai 'claude-sonnet-4-6'
          rm -rf \"\$MOCK_BIN\"
        "
        The status should equal 0
        The output should include "MOCK_CLAUDE:"
        The output should include "--model"
        The output should include "claude-sonnet-4-6"
      End

      It "googleai モデルで gemini コマンドを実行する"
        When run bash -c "
          MOCK_BIN=\"\$(mktemp -d)\"
          printf '#!/usr/bin/env bash\necho \"MOCK_GEMINI:\$*\"\n' > \"\$MOCK_BIN/gemini\"
          chmod +x \"\$MOCK_BIN/gemini\"
          export PATH=\"\$MOCK_BIN:\$PATH\"
          . \"$SCRIPT\"
          echo 'hello' | run_ai 'googleai/gemini-3'
          rm -rf \"\$MOCK_BIN\"
        "
        The status should equal 0
        The output should include "MOCK_GEMINI:"
        The output should include "--model"
        The output should include "googleai/gemini-3"
      End

      It "gemini- モデルで gemini コマンドを実行する"
        When run bash -c "
          MOCK_BIN=\"\$(mktemp -d)\"
          printf '#!/usr/bin/env bash\necho \"MOCK_GEMINI:\$*\"\n' > \"\$MOCK_BIN/gemini\"
          chmod +x \"\$MOCK_BIN/gemini\"
          export PATH=\"\$MOCK_BIN:\$PATH\"
          . \"$SCRIPT\"
          echo 'hello' | run_ai 'gemini-2.5-pro'
          rm -rf \"\$MOCK_BIN\"
        "
        The status should equal 0
        The output should include "MOCK_GEMINI:"
        The output should include "--model"
        The output should include "gemini-2.5-pro"
      End

      It "opusplan エイリアスで --thinking オプションを渡す"
        When run bash -c "
          MOCK_BIN=\"\$(mktemp -d)\"
          printf '#!/usr/bin/env bash\necho \"MOCK_CLAUDE:\$*\"\n' > \"\$MOCK_BIN/claude\"
          chmod +x \"\$MOCK_BIN/claude\"
          export PATH=\"\$MOCK_BIN:\$PATH\"
          . \"$SCRIPT\"
          echo 'hello' | run_ai 'opusplan'
          rm -rf \"\$MOCK_BIN\"
        "
        The status should equal 0
        The output should include "MOCK_CLAUDE:"
        The output should include "--model"
        The output should include "opusplan"
        The output should include "--thinking"
      End
    End

    Describe "エッジケース: 入力値の境界"
      It "空 stdin で run_ai -> exit=0"
        When run bash -c "
          MOCK_BIN=\"\$(mktemp -d)\"
          printf '#!/usr/bin/env bash\necho \"MOCK_CLAUDE:\$*\"\n' > \"\$MOCK_BIN/claude\"
          chmod +x \"\$MOCK_BIN/claude\"
          export PATH=\"\$MOCK_BIN:\$PATH\"
          . \"$SCRIPT\"
          echo '' | run_ai 'sonnet'
          rm -rf \"\$MOCK_BIN\"
        "
        The status should equal 0
        The output should include "MOCK_CLAUDE:"
      End

      It "タイムアウトに文字列を渡すと stderr に 'invalid time interval'"
        When run bash -c "
          MOCK_BIN=\"\$(mktemp -d)\"
          printf '#!/usr/bin/env bash\necho \"MOCK_CLAUDE:\$*\"\n' > \"\$MOCK_BIN/claude\"
          chmod +x \"\$MOCK_BIN/claude\"
          export PATH=\"\$MOCK_BIN:\$PATH\"
          . \"$SCRIPT\"
          echo 'hello' | run_ai 'sonnet' 'notanumber' 2>&1 | cat
          rm -rf \"\$MOCK_BIN\"
        "
        The output should include "invalid time interval"
      End
    End

    Describe "エッジケース: default モデルの _build_ai_command"
      It "default モデルは --model なし、-p のみ"
        When run bash -c "
          MOCK_BIN=\"\$(mktemp -d)\"
          printf '#!/usr/bin/env bash\necho \"MOCK_CLAUDE:\$*\"\n' > \"\$MOCK_BIN/claude\"
          chmod +x \"\$MOCK_BIN/claude\"
          export PATH=\"\$MOCK_BIN:\$PATH\"
          . \"$SCRIPT\"
          echo 'hello' | run_ai 'default'
          rm -rf \"\$MOCK_BIN\"
        "
        The status should equal 0
        The output should include "MOCK_CLAUDE:"
        The output should include "-p"
        The output should not include "--model"
      End
    End

    Describe "エッジケース: copilot モデルの prefix stripping"
      It "github-copilot/gpt-4o -> --model gpt-4o (prefix 除去)"
        When run bash -c "
          MOCK_BIN=\"\$(mktemp -d)\"
          printf '#!/usr/bin/env bash\necho \"MOCK_COPILOT:\$*\"\n' > \"\$MOCK_BIN/copilot\"
          chmod +x \"\$MOCK_BIN/copilot\"
          export PATH=\"\$MOCK_BIN:\$PATH\"
          . \"$SCRIPT\"
          echo 'hello' | run_ai 'github-copilot/gpt-4o'
          rm -rf \"\$MOCK_BIN\"
        "
        The status should equal 0
        The output should include "MOCK_COPILOT:"
        The output should include "--model"
        The output should include "gpt-4o"
        The output should not include "github-copilot"
      End

      It "github-copilot/gemini-2.0 -> --model gemini-2.0 (prefix 除去)"
        When run bash -c "
          MOCK_BIN=\"\$(mktemp -d)\"
          printf '#!/usr/bin/env bash\necho \"MOCK_COPILOT:\$*\"\n' > \"\$MOCK_BIN/copilot\"
          chmod +x \"\$MOCK_BIN/copilot\"
          export PATH=\"\$MOCK_BIN:\$PATH\"
          . \"$SCRIPT\"
          echo 'hello' | run_ai 'github-copilot/gemini-2.0'
          rm -rf \"\$MOCK_BIN\"
        "
        The status should equal 0
        The output should include "MOCK_COPILOT:"
        The output should include "--model"
        The output should include "gemini-2.0"
        The output should not include "github-copilot"
      End

      It "github/unknown-model -> exit=1, stderr 'unsupported model'"
        When run bash -c "
          MOCK_BIN=\"\$(mktemp -d)\"
          printf '#!/usr/bin/env bash\necho \"MOCK_COPILOT:\$*\"\n' > \"\$MOCK_BIN/copilot\"
          chmod +x \"\$MOCK_BIN/copilot\"
          export PATH=\"\$MOCK_BIN:\$PATH\"
          . \"$SCRIPT\"
          echo 'hello' | run_ai 'github/unknown-model'
          rm -rf \"\$MOCK_BIN\"
        "
        The output should equal "1"
        The error should include "unsupported model"
      End

      It "github-copilot/unknown-model -> exit=1, stderr 'unsupported model'"
        When run bash -c "
          MOCK_BIN=\"\$(mktemp -d)\"
          printf '#!/usr/bin/env bash\necho \"MOCK_COPILOT:\$*\"\n' > \"\$MOCK_BIN/copilot\"
          chmod +x \"\$MOCK_BIN/copilot\"
          export PATH=\"\$MOCK_BIN:\$PATH\"
          . \"$SCRIPT\"
          echo 'hello' | run_ai 'github-copilot/unknown-model'
          rm -rf \"\$MOCK_BIN\"
        "
        The output should equal "1"
        The error should include "unsupported model"
      End
    End

  End

End

Describe "実機テスト (claude)"
  Skip if "claude is not installed" ! command -v claude > /dev/null 2>&1

  It "sonnet エイリアスで実際に応答を返す"
    When run bash -c "
      unset CLAUDECODE
      . \"$SCRIPT\"
      echo \"Say 'OK' and nothing else.\" | run_ai 'sonnet' 60
    "
    The status should equal 0
    The output should not equal ""
  End
End

Describe "実機テスト (codex)"
  Skip if "codex is not installed" ! command -v codex > /dev/null 2>&1

  It "gpt-5 モデルで実際に応答を返す"
    When run bash -c "
      . \"$SCRIPT\"
      echo \"Say 'OK' and nothing else.\" | run_ai 'gpt-5' 60
    "
    The status should equal 0
    The output should not equal ""
  End
End

