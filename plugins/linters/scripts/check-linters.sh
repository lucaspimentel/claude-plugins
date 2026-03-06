#!/usr/bin/env bash
missing=()
command -v cslint &>/dev/null    || missing+=("cslint (for .cs files)")
command -v shellcheck &>/dev/null || missing+=("shellcheck (for .sh files)")
pwsh -NoProfile -c 'Get-Module -ListAvailable PSScriptAnalyzer' &>/dev/null || missing+=("PSScriptAnalyzer (for .ps1 files)")

if [[ ${#missing[@]} -gt 0 ]]; then
  echo "[linters plugin] Missing linters:" >&2
  for m in "${missing[@]}"; do echo "  - $m" >&2; done
fi
exit 0
