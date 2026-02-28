---
name: copy-pwd
description: "Copies the current working directory path to the clipboard. Use when the user says 'copy pwd', 'copy path', 'copy current directory', 'copy cwd to clipboard', or any variation of wanting the current directory path in their clipboard."
allowed-tools: Bash(cygpath *), Bash(clip)
---

Run this command:

```bash
cygpath -wa . | clip
```
