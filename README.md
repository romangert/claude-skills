# Personal Claude Code skills

This repo lives at `~/.claude/skills` and holds my personal skills. Each top-level folder with a `SKILL.md` is one skill.
`synced/` is managed by the Claude app and is git-ignored.

## Set up on another machine

`~/.claude/skills` usually already exists there (it contains `synced/`), so don't `git clone` into it. Instead:

```powershell
cd $HOME\.claude\skills
git init -b main
git remote add origin <this-repo-url>
git pull origin main
```

Update later with `git pull`.

## Skills

| Skill | What it does |
|---|---|
| `add-to-solution` | Adds files/folders (e.g. `.specify`, `.claude`, `specs/`) to a Visual Studio `.slnx` so they show in Solution Explorer. Run `/add-to-solution <path>`. |
