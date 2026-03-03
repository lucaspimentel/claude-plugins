---
name: wt-panes
description: "Open, split, or arrange Windows Terminal panes and tabs using wt.exe. Use when the user says 'open panes', 'split terminal', 'new tab', 'side by side', 'terminal layout', 'split pane with WSL', or any variation of wanting to launch Windows Terminal panes or tabs."
model: haiku
allowed-tools:
  - Bash(wt *)
---

Generate and immediately execute a `wt.exe` command to open the requested panes or tabs.

## Rules

1. **Always use `-w 0`** to target the current window (without it, `wt` opens a new window).
2. **Always use `-d .`** on every subcommand so new panes/tabs open in the current directory.
3. **Execute immediately** — do not preview or ask for confirmation.
4. Chain multiple subcommands with `\;` (backslash-semicolon) in bash.

## `wt` subcommand reference

| Subcommand | Alias | Purpose |
|------------|-------|---------|
| `new-tab` | `nt` | Open a new tab |
| `split-pane` | `sp` | Split the current pane |

## Key flags

| Flag | Description |
|------|-------------|
| `-H` | Split horizontally (new pane below) |
| `-V` | Split vertically (new pane to the right) |
| `-s <ratio>` | Size of the new pane as a fraction (e.g. `0.5`) |
| `-p "<profile>"` | Profile name (e.g. `"Windows PowerShell"`, `"Ubuntu"`) |
| `-d <dir>` | Starting directory (always use `-d .`) |
| `--title "<title>"` | Set the pane/tab title |

## Example patterns

**Two panes side by side (vertical split):**
```bash
wt -w 0 split-pane -V -d .
```

**Two panes stacked (horizontal split):**
```bash
wt -w 0 split-pane -H -d .
```

**Three-pane layout (left + top-right + bottom-right):**
```bash
wt -w 0 split-pane -V -s 0.5 -d . \; split-pane -H -s 0.5 -d .
```

**New tab with a specific profile:**
```bash
wt -w 0 new-tab -p "Ubuntu" -d .
```

**Split pane with WSL:**
```bash
wt -w 0 split-pane -V -p "Ubuntu" -d .
```

**New tab + split pane:**
```bash
wt -w 0 new-tab -d . \; split-pane -V -d .
```

## Reference

- [Windows Terminal command-line arguments](https://raw.githubusercontent.com/MicrosoftDocs/terminal/live/TerminalDocs/command-line-arguments.md)

## Execution

Run the generated command directly with the `Bash` tool using `wt ...`.
