#!/usr/bin/env bash
# bootstrap.spec.sh - ShellSpec tests for scripts/lib/bootstrap.sh
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

Include spec_helper.sh

SCRIPT="${DECKRD_LIB_DIR}/bootstrap.sh"

Describe "bootstrap.sh"

# ============================================================================
# source 可能であること
# ============================================================================
Describe "Given: no pre-existing environment variables"

Describe "When: source bootstrap.sh"
It "[Normal] Should: exit with status 0"
When run bash -c "source \"$SCRIPT\" && echo ok"
The status should equal 0
The output should equal "ok"
End
End

End

# ============================================================================
# PROJECT_ROOT
# ============================================================================
Describe "Given: no PROJECT_ROOT set"

Describe "When: source bootstrap.sh"
It "[Normal] Should: PROJECT_ROOT not be empty"
When run bash -c "source \"$SCRIPT\" && echo \"\$PROJECT_ROOT\""
The status should equal 0
The output should not equal ""
End
End

End

Describe "Given: PROJECT_ROOT is pre-set to /tmp"

Describe "When: source bootstrap.sh"
It "[Normal] Should: PROJECT_ROOT remain /tmp"
When run bash -c "export PROJECT_ROOT=/tmp; source \"$SCRIPT\" && echo \"\$PROJECT_ROOT\""
The status should equal 0
The output should equal "/tmp"
End
End

End

# ============================================================================
# SCRIPTS_DIR
# ============================================================================
Describe "Given: no SCRIPTS_DIR set"

Describe "When: source bootstrap.sh"
It "[Normal] Should: SCRIPTS_DIR end with /scripts"
When run bash -c "source \"$SCRIPT\" && echo \"\$SCRIPTS_DIR\""
The status should equal 0
The output should end with "/scripts"
End
End

End

Describe "Given: SCRIPTS_DIR is pre-set to /tmp/scripts"

Describe "When: source bootstrap.sh"
It "[Normal] Should: SCRIPTS_DIR remain /tmp/scripts"
When run bash -c "export SCRIPTS_DIR=/tmp/scripts; source \"$SCRIPT\" && echo \"\$SCRIPTS_DIR\""
The status should equal 0
The output should equal "/tmp/scripts"
End
End

End

# ============================================================================
# DECKRD_LIB_DIR
# ============================================================================
Describe "Given: no DECKRD_LIB_DIR set"

Describe "When: source bootstrap.sh"
It "[Normal] Should: DECKRD_LIB_DIR end with /deckrd/skills/deckrd/scripts/lib"
When run bash -c "source \"$SCRIPT\" && echo \"\$DECKRD_LIB_DIR\""
The status should equal 0
The output should end with "/deckrd/skills/deckrd/scripts/lib"
End
End

End

# ============================================================================
# PLUGINS_DIR
# ============================================================================
Describe "Given: no PLUGINS_DIR set"

Describe "When: source bootstrap.sh"
It "[Normal] Should: PLUGINS_DIR end with /plugins"
When run bash -c "source \"$SCRIPT\" && echo \"\$PLUGINS_DIR\""
The status should equal 0
The output should end with "/plugins"
End
End

End

# ============================================================================
# ASSETS_DIR
# ============================================================================
Describe "Given: no ASSETS_DIR set"

Describe "When: source bootstrap.sh"
It "[Normal] Should: ASSETS_DIR end with /.claude"
When run bash -c "source \"$SCRIPT\" && echo \"\$ASSETS_DIR\""
The status should equal 0
The output should end with "/.claude"
End
End

End

# ============================================================================
# AGENTS_DIR
# ============================================================================
Describe "Given: no AGENTS_DIR set"

Describe "When: source bootstrap.sh"
It "[Normal] Should: AGENTS_DIR end with /.claude/agents"
When run bash -c "source \"$SCRIPT\" && echo \"\$AGENTS_DIR\""
The status should equal 0
The output should end with "/.claude/agents"
End
End

End

# ============================================================================
# 冪等性
# ============================================================================
Describe "Given: bootstrap.sh is already sourced"

Describe "When: source bootstrap.sh again"
It "[Normal] Should: PROJECT_ROOT remain unchanged after double source"
When run bash -c "source \"$SCRIPT\" && FIRST=\"\$PROJECT_ROOT\" && source \"$SCRIPT\" && [[ \"\$PROJECT_ROOT\" == \"\$FIRST\" ]] && echo ok"
The status should equal 0
The output should equal "ok"
End
End

End

End
