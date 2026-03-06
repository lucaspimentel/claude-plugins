---
name: wt-tabs
description: "Manage Windows Terminal tabs using wt.exe. Use when the user says 'open tabs', 'new tab', 'switch tab', 'focus tab', 'move pane to tab', 'tab color', 'tab title', 'multiple tabs', 'rename tab', or any variation of wanting to manage Windows Terminal tabs."
model: haiku
allowed-tools:
  - Bash(wt.exe *)
---

## Platform

This skill requires Windows Terminal (`wt.exe`), available on native Windows and WSL.
If `wt.exe` is not found in `PATH`, tell the user this skill requires Windows or WSL and **stop** — do not attempt to run any commands.

Generate and immediately execute a `wt.exe` command to manage tabs.

## Rules

1. **Always use `-w 0`** to target the current window (without it, `wt.exe` opens a new window).
2. **Always use `-d .`** on every subcommand so new tabs open in the current directory.
3. **Execute immediately** — do not preview or ask for confirmation.
4. Chain multiple subcommands with `\;` (backslash-semicolon) in bash.

## `wt.exe` subcommand reference

| Subcommand | Alias | Purpose |
|------------|-------|---------|
| `new-tab` | `nt` | Open a new tab |
| `focus-tab` | `ft` | Switch to a tab by zero-based index |
| `move-pane` | `mp` | Move the active pane to another tab |

## Key flags

| Flag | Description |
|------|-------------|
| `-p "<profile>"` | Profile name (e.g. `"Windows PowerShell"`, `"Ubuntu"`) |
| `-d <dir>` | Starting directory (always use `-d .`) |
| `-t <index>` | Target tab index (zero-based) for `focus-tab` and `move-pane` |
| `--title "<title>"` | Set the tab title |
| `--tabColor #RRGGBB` | Set the tab color |
| `--suppressApplicationTitle` | Lock a custom title so the shell doesn't overwrite it |

## Example patterns

**Open a new tab:**
```bash
wt.exe -w 0 new-tab -d .
```

**Open 3 tabs with different profiles:**
```bash
wt.exe -w 0 nt -p "Windows PowerShell" -d . \; nt -p "Ubuntu" -d . \; nt -p "Git Bash" -d .
```

**Open tabs with custom colors:**
```bash
wt.exe -w 0 nt -d . --title "API" --tabColor #009999 \; nt -d . --title "Web" --tabColor #994400
```

**Focus a specific tab (e.g. tab 2):**
```bash
wt.exe -w 0 focus-tab -t 2
```

**Move active pane to tab 1:**
```bash
wt.exe -w 0 move-pane -t 1
```

**Named tabs with locked titles:**
```bash
wt.exe -w 0 nt -d . --title "Server" --suppressApplicationTitle \; nt -d . --title "Client" --suppressApplicationTitle
```

## Reference

- [Windows Terminal command-line arguments](https://raw.githubusercontent.com/MicrosoftDocs/terminal/live/TerminalDocs/command-line-arguments.md)

## Execution

Run the generated command directly with the `Bash` tool using `wt.exe ...`.
