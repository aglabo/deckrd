#!/usr/bin/env bash
# src: ./scripts/run-textlint.sh
# @(#) : markdownlint-runner runner
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -euo pipefail
pnpx markdownlint-cli2 --config "${XDG_CONFIG_HOME}/linters/markdownlint/.markdownlint-cli2.yaml" "$@"

