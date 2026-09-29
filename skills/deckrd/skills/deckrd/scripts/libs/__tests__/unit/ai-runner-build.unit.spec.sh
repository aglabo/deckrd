#!/usr/bin/env bash
# ai-runner-build.spec.sh - ShellSpec tests for _build_ai_command
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# shellcheck disable=SC1090

_RUNTIME_BOOTSTRAP="${SHELLSPEC_PROJECT_ROOT}/skills/deckrd/skills/deckrd/scripts/libs/bootstrap.lib.sh"
. "$_RUNTIME_BOOTSTRAP"
unset _RUNTIME_BOOTSTRAP

Include ../spec_helper.sh

SCRIPT="${DECKRD_LIB_DIR}/ai-runner.lib.sh"
. "$SCRIPT"

Describe "ai-runner.sh"
  Describe "T-LIB-ABC: _build_ai_command"
    Describe "Given: claude CLI とモデル名"
      Describe "When: _build_ai_command を呼ぶ"
        Parameters
          "claude" "claude-3-opus" "--model" "claude-3-opus"
          "claude" "sonnet" "--model" "sonnet"
          "claude" "opus" "--model" "opus"
          "claude" "haiku" "--model" "haiku"
          "claude" "opusplan" "--model" "opusplan"
        End

        It "Then: [Normal] T-LIB-ABC-01: cmd に $3 $4 が含まれる"
          _cmd=()
          When call _build_ai_command "$1" "$2" _cmd
          The status should equal 0
          The variable '_cmd[*]' should include "$3"
          The variable '_cmd[*]' should include "$4"
        End
      End
    End

    Describe "Given: 特殊オプションを持つモデル名"
      Describe "When: _build_ai_command を呼ぶ"
        It "Then: [Normal] T-LIB-ABC-02: opusplan は --thinking を含む"
          _cmd=()
          When call _build_ai_command "claude" "opusplan" _cmd
          The status should equal 0
          The variable '_cmd[*]' should include "--thinking"
        End

        It "Then: [Normal] T-LIB-ABC-03: sonnet-1m は --context-window 1000000 を含む"
          _cmd=()
          When call _build_ai_command "claude" "sonnet-1m" _cmd
          The status should equal 0
          The variable '_cmd[*]' should include "--context-window"
          The variable '_cmd[*]' should include "1000000"
        End

        It "Then: [Normal] T-LIB-ABC-04: default は --model を含まない"
          _cmd=()
          When call _build_ai_command "claude" "default" _cmd
          The status should equal 0
          The variable '_cmd[*]' should not include "--model"
        End
      End
    End

    Describe "Given: copilot CLI とプレフィックス付きモデル名"
      Describe "When: _build_ai_command を呼ぶ"
        It "Then: [Normal] T-LIB-ABC-05: github-copilot/gpt-4o -> model は gpt-4o (prefix 除去)"
          _cmd=()
          When call _build_ai_command "copilot" "github-copilot/gpt-4o" _cmd
          The status should equal 0
          The variable '_cmd[*]' should include "gpt-4o"
          The variable '_cmd[*]' should not include "github-copilot"
        End
      End
    End

    Describe "Given: copilot CLI と非対応モデル名"
      Describe "When: _build_ai_command を呼ぶ"
        It "Then: [Error] T-LIB-ABC-06: exit 1 を返す"
          _cmd=()
          When call _build_ai_command "copilot" "unknown-model" _cmd
          The status should equal 1
        End
      End
    End

    Describe "Given: codex CLI と openai 系モデル名"
      Describe "When: _build_ai_command を呼ぶ"
        It "Then: [Normal] T-LIB-ABC-10: codex は exec と --model <model> を含む"
          _cmd=()
          When call _build_ai_command "codex" "gpt-4o" _cmd
          The status should equal 0
          The variable '_cmd[*]' should include "exec"
          The variable '_cmd[*]' should include "--model"
          The variable '_cmd[*]' should include "gpt-4o"
        End

        # codex exec は cwd が git リポジトリ外だと起動を拒む。run_ai は cd しないので、
        # このフラグが落ちると「リポジトリ外の呼び出し元からは無言で空応答」へ逆戻りする
        It "Then: [Normal] T-LIB-ABC-11: codex は --skip-git-repo-check を保つ"
          _cmd=()
          When call _build_ai_command "codex" "gpt-4o" _cmd
          The status should equal 0
          The variable '_cmd[*]' should include "--skip-git-repo-check"
        End

        # 短いフラグは部分一致では守れない。"-s" は "--skip-git-repo-check" の部分文字列
        # としても一致するため、`should include "-s"` は -s read-only を消しても PASS する。
        # 並び順も含めて完全一致で固定する
        It "Then: [Normal] T-LIB-ABC-12: codex の argv は隔離フラグ込みで完全一致する"
          _cmd=()
          When call _build_ai_command "codex" "gpt-4o" _cmd
          The status should equal 0
          The variable '_cmd[*]' should equal "codex exec --model gpt-4o --skip-git-repo-check --ignore-user-config -s read-only --color never"
        End

        # ユーザー設定 (~/.codex/config.toml) の MCP サーバ起動を止めるフラグ。これが落ちると
        # codex exec が [mcp_servers.*] を起動し、MCP サーバが cwd 配下に作業ファイル
        # (.cocoindex_code/ 等) を作って掴んだままにするため、呼び出し元の cwd が汚れる
        It "Then: [Normal] T-LIB-ABC-13: codex は --ignore-user-config を保つ"
          _cmd=()
          When call _build_ai_command "codex" "gpt-4o" _cmd
          The status should equal 0
          The variable '_cmd[*]' should include "--ignore-user-config"
        End
      End
    End

    Describe "Given: claude CLI と全モデル分岐"
      Describe "When: _build_ai_command を呼ぶ"
        Parameters
          "default"
          "sonnet"
          "sonnet-1m"
          "opusplan"
          "claude-3-opus"
        End

        It "Then: [Normal] T-LIB-ABC-07: $1 は --permission-mode を含まない"
          _cmd=()
          When call _build_ai_command "claude" "$1" _cmd
          The status should equal 0
          The variable '_cmd[*]' should not include "--permission-mode"
          The variable '_cmd[*]' should not include "acceptEdits"
        End

        It "Then: [Normal] T-LIB-ABC-08: $1 は --strict-mcp-config と MCP 遮断設定を保つ"
          _cmd=()
          When call _build_ai_command "claude" "$1" _cmd
          The status should equal 0
          The variable '_cmd[*]' should include "--strict-mcp-config"
          The variable '_cmd[*]' should include "--mcp-config"
          The variable '_cmd[*]' should include '{"mcpServers":{}}'
        End

        It "Then: [Normal] T-LIB-ABC-09: $1 は非対話実行の -p を保つ"
          _cmd=()
          When call _build_ai_command "claude" "$1" _cmd
          The status should equal 0
          The variable '_cmd[*]' should include "-p"
        End
      End
    End
  End
End
