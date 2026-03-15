#!/usr/bin/env bash
# spec_helper.sh - delegate to parent tests/spec_helper.sh
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# shellcheck disable=SC1091
. "$(dirname "${BASH_SOURCE[0]}")/../spec_helper.sh"
