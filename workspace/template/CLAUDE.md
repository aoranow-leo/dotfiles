# CLAUDE.md — workspace root

This folder holds one or more client Git repositories and a local wiki side by side.
The root itself is **not** a Git repository, and that is on purpose.

## Layout

```
./                     workspace root (no git). Start Claude Code here.
  CLAUDE.md            this file
  .claude/settings.json  deny rules for the whole workspace
  guides/              step-by-step runbooks the human puts here (read-only for you)
  wiki/                local Obsidian wiki (no git). Its own CLAUDE.md applies inside it.
  refs/                read-only reference clones (e.g. refs/servicenow-docs). Never edit or commit.
  tools/               helper scripts (tools/docsearch.py)
  <repo>/              every other folder that contains .git is a client repository
```

Settings and hooks load only from the folder where Claude Code starts. Start it **here**, at the
root, so `.claude/settings.json` applies. A repo's own `.claude/settings.json` does not apply
when you start here; the human merges what matters from it into the root file.

## Rules

1. **One repository per task.** Name the repository in every Git command:
   `git -C <repo> status`, `git -C <repo> switch -c <branch>`. Never run Git in the root or in
   `wiki/`, and never run `git init` anywhere.
2. **wiki/ and the repositories do not mix.** Never copy wiki pages, notes or raw sources into a
   repository. You may read a repository file and record what it says in the wiki, linking to it
   by path. The "no git" rule in `wiki/CLAUDE.md` covers only `wiki/`.
3. **Repository work goes through a pull request.** Branch, commit, push the branch, open a
   **draft** PR. Never push to `main` or `master`, never force-push, never merge. Inside a
   repository, its own `CLAUDE.md` and README conventions come first.
4. **No business data.** From instances and systems, read only metadata and configuration.
   Never save business records, personal data, credentials or tokens in `wiki/` or in a
   repository. If a command prints such data, do not save it; tell the human.
5. **Never write to a remote system** (instances, ticketing, chat) unless the human asks for that
   exact action. Some of these commands are blocked in settings; do not look for a way around.
6. **guides/** are followed exactly when the human asks you to run one. If a step does not match
   what you see, stop and report; do not improvise.
7. When you are not sure which folder a change belongs to, ask before writing.
8. **refs/ is for reading only.** Never edit, delete, commit or push anything in `refs/`.

## Looking things up in refs/

To answer a platform question, search the reference docs instead of answering from memory:

1. `python3 tools/docsearch.py search servicenow-docs <words>`: the 10 best-matching pages, with
   path and snippet. Add `--area <area>` to narrow (`python3 tools/docsearch.py areas servicenow-docs`
   lists them), `"quotes"` for a phrase, `-n 20` for more.
2. Read the 1–3 pages that fit, by path. Cite the path (or the URL it shows) in your answer.
3. Use `rg` (Grep) only for exact strings such as a table, property or API name, and limit it to
   one area folder; across all of refs/ it returns thousands of lines.
4. If nothing fits, say so. The docs match one release (see `git -C refs/servicenow-docs branch`).
