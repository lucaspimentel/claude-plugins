#!/bin/bash
FILE_PATH=$(jq -r ".tool_input.file_path")
if [[ "$FILE_PATH" == *.sh ]]; then
  if ! command -v shellcheck &> /dev/null; then
    echo "shellcheck not installed." >&2
    exit 0
  fi
  command -v dos2unix &> /dev/null && dos2unix -q "$FILE_PATH" 2>/dev/null
  OUTPUT=$(shellcheck "$FILE_PATH" 2>&1)
  if [[ -n "$OUTPUT" ]]; then
    echo "$OUTPUT" >&2
    exit 2
  fi
fi
