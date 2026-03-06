#!/usr/bin/env bash
FILE_PATH=$(jq -r ".tool_input.file_path")
if [[ "$FILE_PATH" == *.ps1 ]]; then
  OUTPUT=$(pwsh -NoProfile -File "$(dirname "$0")/ps-lint.ps1" "$FILE_PATH" 2>&1)
  if [[ -n "$OUTPUT" ]]; then
    echo "$OUTPUT" >&2
    exit 2
  fi
fi
