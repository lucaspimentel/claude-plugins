#!/usr/bin/env bash
if ! command -v powershell.exe &>/dev/null; then
  exit 0
fi
script_dir="$(cd "$(dirname "$0")" && pwd)"
ps_script="$script_dir/notify.ps1"
if command -v wslpath &>/dev/null; then
  ps_script="$(wslpath -w "$ps_script")"
fi
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$ps_script"
