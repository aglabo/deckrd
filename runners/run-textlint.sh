#!/usr/bin/env bash
# src: ./scripts/run-textlint.sh
# @(#) : texlint runner
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -euo pipefail
pnpx textlint --config "${XDG_CONFIG_HOME}/linters/textlint/textlintrc.yaml" "$@"

