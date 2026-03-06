#!/usr/bin/env bash
FILE_PATH=$(jq -r ".tool_input.file_path")
if [[ "$FILE_PATH" == *.cs ]]; then
  if ! command -v cslint &> /dev/null; then
    echo "cslint not installed." >&2
    exit 0
  fi
  OUTPUT=$(cslint "$FILE_PATH" 2>&1)
  if [[ -n "$OUTPUT" ]]; then
    echo "$OUTPUT" >&2
    exit 2
  fi
fi
