---
name: "add-to-solution"
description: "Add files (or whole folders) to the Visual Studio .slnx solution tree so they appear in Solution Explorer. Use when the user asks to add/show a file or folder in the solution tree, or after creating files in hidden folders like .specify, .claude or specs/."
argument-hint: "File or folder paths to add (e.g. specs/001-feature)"
user-invocable: true
disable-model-invocation: false
---

## User Input

```text
$ARGUMENTS
```

## Steps

1. Determine the paths to add: the ones in the user input; if empty, ask which files or folders.
2. Run from the repo root (the folder containing the `.slnx`):

   ```powershell
   powershell -NoProfile -File "$HOME/.claude/skills/add-to-solution/add-to-slnx.ps1" <path> [<path> ...]
   ```

   (`pwsh` works too if installed)
3. The script:
   - expands directories to every file not ignored by git,
   - mirrors the directory structure as `<Folder Name="/dir/sub/">` entries in the `.slnx` (root-level files go to `/Solution Items/`),
   - creates missing folders, skips files already listed, never removes anything.
4. Report the "added ..." lines. Run `dotnet build <solution>.slnx` to confirm the XML is valid, and tell the user to reload the solution in Visual Studio.
