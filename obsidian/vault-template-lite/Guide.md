---
type: sistema
summary: "How to use this wiki: what to ask the LLM and where each thing lives."
---

# Guide

The LLM (Claude Code, opened in this folder or in the workspace root above it) keeps this wiki. You bring sources and ask questions; it writes, links and checks the pages.

## Rules on this machine

- No git and no sync. The wiki lives only here.
- Nothing leaves this machine.
- No community plugins in Obsidian.

## Where things live

| Folder or file | What it is | Who edits it |
|---|---|---|
| `raw/` | sources as received | you drop files; the LLM only reads |
| `sources/` | one page per source read | LLM |
| `wiki/` | one page per topic | LLM |
| `notes/` | meetings and dated notes | LLM |
| `Tasks.md` | open tasks | LLM |
| `index.md` | map of everything (generated) | script |
| `log.md` | what changed, newest on top | LLM |
| `CLAUDE.md` | rules the LLM follows | you |

## What to ask

1. **Ingest:** "I put `raw/minutes.md` there. Read it, tell me the key points, then ingest it."
2. **Ask:** "What do I already know about X? Answer with links."
3. **Note:** "Write down today's meeting: …"
4. **Task:** "Add task X, due Friday." · "Mark X as done."
5. **Check:** "Run `scripts/wiki.py` and tell me what came up."

## Checking

`python3 scripts/wiki.py` regenerates `index.md` and lists what is wrong. The LLM fixes `ERROR` lines itself and tells you about `WARNING` lines.

Start at [[index]]. Tasks in [[Tasks]], history in [[log]].
