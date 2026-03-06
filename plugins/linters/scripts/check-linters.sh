#!/usr/bin/env bash
missing=()
command -v cslint &>/dev/null    || missing+=("cslint (for .cs files)")
command -v shellcheck &>/dev/null || missing+=("shellcheck (for .sh files)")
pwsh -NoProfile -c 'Get-Module -ListAvailable PSScriptAnalyzer' &>/dev/null || missing+=("PSScriptAnalyzer (for .ps1 files)")

if [[ ${#missing[@]} -gt 0 ]]; then
  msg="[linters plugin] Missing linters:"
  for m in "${missing[@]}"; do msg+=$'\n'"  - $m"; done
  # Escape for JSON string (newlines -> \n, quotes -> \")
  json_msg="${msg//\\/\\\\}"
  json_msg="${json_msg//\"/\\\"}"
  json_msg="${json_msg//$'\n'/\\n}"
  echo "{\"systemMessage\":\"${json_msg}\"}"
fi
exit 0
