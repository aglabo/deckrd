#!/usr/bin/env bash
# src: ./skills/bdd-coder/skills/bdd-coder/scripts/check-ids/languages.sh
# @(#) : language table of the test case ID checker
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT
# SC2034: check-test-ids.sh reads the table
# shellcheck shell=bash disable=SC2034

# The languages that --lang accepts, each with the <id> of its plugin file,
# <id>-id-checker.plugin.sh
declare -gA LANG_PLUGIN=([sh]=sh [ts]=tsjs [js]=tsjs [dart]=dart [go]=go)
