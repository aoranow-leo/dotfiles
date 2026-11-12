# CLAUDE.md — workspace root

This folder holds one or more client Git repositories, a local wiki, guides and reference docs side
by side. The root itself is **not** a Git repository, and that is on purpose.

## Layout

```
<root>/                (no git)
  CLAUDE.md            this file; it also loads when Claude Code starts inside a repo below
  <repo>/              every folder with .git is a client repository (its own rules apply)
  wiki/                local Obsidian wiki (no git). Its own CLAUDE.md has the wiki rules.
  guides/              step-by-step runbooks (read-only for you)
  refs/                read-only reference clones (e.g. refs/servicenow-docs)
  tools/               helper scripts (tools/docsearch.py)
```

## Where Claude Code starts

- **Work on a repository, or run a guide: start inside that repository** (`cd <repo> && claude`).
  Its `.claude/settings.json` (the client's rules) applies, plus the human's personal rules.
  The repo's `.claude/settings.local.json` gives access to `../wiki`, `../guides`, `../refs`
  and `../tools`. From there, those folders are `../wiki/...`, `../guides/...` and so on.
- **Work only on the wiki: start inside `wiki/`.**
- Starting at the root skips every repository's rules. Do not run guides or Git work from the root.

## Rules

1. **Git only inside a repository.** Never run Git in the root or in `wiki/`, never `git init`.
2. **Repository work goes through a pull request.** Branch, commit, push the branch, open a
   **draft** PR. Never push to `main` or `master`, never force-push, never merge. The
   repository's own `CLAUDE.md`, README and settings come first.
3. **The wiki is part of every run.** When you finish a guide, or learn something a later session
   will need (a decision, a confirmed fact, an open question), record it in `../wiki`. Read
   `../wiki/CLAUDE.md` first: it does not load on its own when you start in a repository.
   Then run `python3 ../wiki/scripts/wiki.py` until it says OK.
4. **wiki/ and the repositories do not mix.** The wiki records facts, decisions and links (paths,
   PR URLs). Never copy pulled data, scripts or JSON into the wiki, and never copy wiki pages
   into a repository.
5. **No business data.** From instances and systems, read only metadata and configuration.
   Never save business records, personal data, credentials or tokens anywhere here.
6. **Never write to a remote system** (instances, ticketing, chat) unless the human asks for that
   exact action. Some commands are blocked in settings; do not look for a way around.
7. **guides/** are followed exactly when the human asks you to run one. If a step does not match
   what you see, stop and report; do not improvise.
8. **refs/ is for reading only.** Never edit, delete, commit or push anything in it.

## Looking things up in refs/

To answer a platform question, search the reference docs instead of answering from memory
(paths below are from inside a repository; from the root drop the `../`):

1. `python3 ../tools/docsearch.py search servicenow-docs <words>`: the 10 best-matching pages,
   with path and snippet. `--area <area>` narrows (`... areas servicenow-docs` lists them),
   `"quotes"` searches a phrase, `-n 20` shows more.
2. Read the 1–3 pages that fit, by the path it prints. Cite the path or URL in your answer.
3. Use `rg` only for exact strings (a table, property or API name), inside one area folder.
4. If nothing fits, say so. The docs match one release (`git -C ../refs/servicenow-docs branch`).
