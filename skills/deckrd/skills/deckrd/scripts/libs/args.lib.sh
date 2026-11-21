#!/usr/bin/env bash
# src: ./skills/deckrd/skills/deckrd/scripts/libs/args.lib.sh
# @(#) : Declarative command-line argument parser library
#
# Copyright (c) 2026- aglabo <https://github.com/aglabo>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT
#
# USAGE: source this file, do NOT execute directly.

# shellcheck shell=bash
# shellcheck disable=SC2034 # OPTIONS, OPTIONS_SET and ARGS_ERROR are consumed by callers

if [[ -n ${_ARGS_LIB_LOADED:-}   ]]; then
  return 0
fi
readonly _ARGS_LIB_LOADED=1

# args_init - Reset all declarations and parse results
#
# Recreates OPTIONS, OPTIONS_SET and the internal tables as globals and clears
# ARGS_ERROR. Call it before declaring options for a new parse.
#
# @return 0 always
args_init()
            {
  unset OPTIONS OPTIONS_SET _ARGS_KEY_OF _ARGS_TYPE _ARGS_POSITIONAL
  declare -gA OPTIONS=() OPTIONS_SET=() _ARGS_KEY_OF=() _ARGS_TYPE=()
  declare -ga _ARGS_POSITIONAL=()
  declare -g ARGS_ERROR=""
}

# _args_register - Record the type of a key and map each option name to it
#
# @arg $1 string key  Result key in OPTIONS
# @arg $2 string type flag | value
# @arg $@ string opts Option names
_args_register()
                 {
  local key="$1" type="$2"
  shift 2
  _ARGS_TYPE["$key"]="$type"
  local opt
  for opt in "$@"; do
    _ARGS_KEY_OF["$opt"]="$key"
  done
}

# args_flag - Declare a boolean flag option
#
# The flag defaults to false and becomes true when any of its names is given.
#
# @arg $1 string key  Result key in OPTIONS
# @arg $@ string opts Option names (e.g. -f --force)
args_flag()
            {
  local key="$1"
  shift
  _args_register "$key" flag "$@"
  OPTIONS["$key"]=false
}

# args_value - Declare an option that takes a value
#
# OPTIONS[key] starts as the default and is replaced by the value given after
# any of the option names.
#
# @arg $1 string key     Result key in OPTIONS
# @arg $2 string default Value used when the option is not given
# @arg $@ string opts    Option names (e.g. -m --model)
args_value()
             {
  local key="$1" default="$2"
  shift 2
  _args_register "$key" value "$@"
  OPTIONS["$key"]="$default"
}

# args_positional - Declare positional argument keys in order
#
# @arg $@ string keys Result keys in OPTIONS, assigned in declaration order
args_positional()
                  {
  _ARGS_POSITIONAL+=("$@")
  local key
  for key in "$@"; do
    OPTIONS["$key"]=""
  done
}

# _args_take_value - Store the value that follows a value option
#
# @arg $1 string key   Result key in OPTIONS
# @arg $2 string opt   Option name as passed (used in the error message)
# @arg $3 string value Next argument; absent or empty counts as missing
# @set ARGS_ERROR "<opt> requires a value" when the value is missing
# @return 0 when stored, 1 when the value is missing
_args_take_value()
                   {
  local key="$1" opt="$2"
  if [[ -z ${3-}   ]]; then
    ARGS_ERROR="${opt} requires a value"
    return 1
  fi
  OPTIONS["$key"]="$3"
}

# _args_option - Apply one option token and the value it consumes
#
# Accepts "--name=value" (inline value, split at the first "=" so the value
# may contain "=") or "--name [value]". A flag given in "=" form is rejected.
# OPTIONS_SET[key] is marked only after the option is applied successfully.
#
# @arg $1 string arg  Option token as passed
# @arg $2 string next Following argument (used only by value options)
# @set _ARGS_SHIFT Number of arguments consumed (1 or 2)
# @set ARGS_ERROR  "Unknown option: <name>", "<name> does not take a value"
#                  or "<name> requires a value" on error
# @return 0 when applied, 1 on error
_args_option()
               {
  local arg="$1" name="$1" inline=false
  if [[ $arg == --*=*   ]]; then
    name="${arg%%=*}"
    inline=true
  fi
  local key="${_ARGS_KEY_OF[$name]:-}"
  if [[ -z $key   ]]; then
    ARGS_ERROR="Unknown option: ${name}"
    return 1
  fi
  _ARGS_SHIFT=1
  if [[ ${_ARGS_TYPE[$key]} == value   ]]; then
    if [[ $inline == true   ]]; then
      _args_take_value "$key" "$name" "${arg#*=}" || return 1
    else
      _args_take_value "$key" "$name" "${2-}" || return 1
      _ARGS_SHIFT=2
    fi
  elif [[ $inline == true   ]]; then
    ARGS_ERROR="${name} does not take a value"
    return 1
  else
    OPTIONS["$key"]=true
  fi
  OPTIONS_SET["$key"]=true
}

# _args_positional - Assign an argument to the next declared positional key
#
# @arg $1 string pos Index of the next positional key
# @arg $2 string arg Argument to assign
# @set ARGS_ERROR "Unexpected argument: <arg>" when no key is left
# @return 0 when assigned, 1 when more arguments than declared keys
_args_positional()
                   {
  local pos="$1" arg="$2"
  if ((pos >= ${#_ARGS_POSITIONAL[@]})); then
    ARGS_ERROR="Unexpected argument: ${arg}"
    return 1
  fi
  local key="${_ARGS_POSITIONAL[$pos]}"
  OPTIONS["$key"]="$arg"
  OPTIONS_SET["$key"]=true
}

# parse_args - Parse arguments against the current declarations
#
# -h / --help need no declaration: they set OPTIONS[SHOW_HELP]=true and stop
# parsing at once. A value option accepts "--name value" or "--name=value";
# a flag rejects "--name=value". Every key applied successfully is marked in
# OPTIONS_SET (a failed option leaves no mark).
# Writes nothing to stdout or stderr.
#
# @arg $@ string args Command-line arguments
# @return 0 on success (including help), 1 on error (ARGS_ERROR holds the message)
parse_args()
             {
  ARGS_ERROR=""
  OPTIONS[SHOW_HELP]=false
  local arg pos=0
  while (($# > 0)); do
    arg="$1"
    if [[ $arg == --help || $arg == -h     ]]; then
      OPTIONS[SHOW_HELP]=true
      return 0
    fi
    if [[ $arg != -*   ]]; then
      _args_positional "$pos" "$arg" || return 1
      pos=$((pos + 1))
      shift
      continue
    fi
    _args_option "$@" || return 1
    shift "$_ARGS_SHIFT"
  done
  return 0
}
