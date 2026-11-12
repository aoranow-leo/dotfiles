#!/usr/bin/env python3
"""settings_merge.py — writes Claude Code settings for the workspace without touching other keys.

  settings_merge.py user  <user-deny.json> <~/.claude/settings.json>   add missing personal deny rules
  settings_merge.py repo  <workspace> <repo>                           write <repo>/.claude/settings.local.json
  settings_merge.py check-user <user-deny.json> <~/.claude/settings.json>
  settings_merge.py check-repo <workspace> <repo>

Existing rules and keys are kept. A changed file is backed up as <file>.bak.<timestamp>.
Exit code 1 when a check fails.
"""
import json
import shutil
import sys
import time
from pathlib import Path

NEIGHBOURS = ("wiki", "guides", "refs", "tools")


def load(p):
    p = Path(p)
    if not p.exists() or not p.read_text(encoding="utf-8").strip():
        return {}
    return json.loads(p.read_text(encoding="utf-8"))


def save(p, data):
    p = Path(p)
    p.parent.mkdir(parents=True, exist_ok=True)
    if p.exists():
        shutil.copy2(p, f"{p}.bak.{time.strftime('%Y%m%d%H%M%S')}")
    p.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def add_unique(lst, items):
    added = [i for i in items if i not in lst]
    lst.extend(added)
    return added


def repo_rules(ws):
    ws = Path(ws).resolve()
    dirs = [str(ws / n) for n in NEIGHBOURS if (ws / n).is_dir()]
    deny = [f"Edit(/{ws / 'refs'}/**)"] if (ws / "refs").is_dir() else []
    return dirs, deny


def main(argv):
    if len(argv) != 3:
        sys.exit(__doc__)
    cmd, a, b = argv
    if cmd == "user":
        want = load(a)["deny"]
        data = load(b)
        added = add_unique(data.setdefault("permissions", {}).setdefault("deny", []), want)
        if added:
            save(b, data)
        print(f"OK    {b}: {len(added)} deny rule(s) added, {len(want) - len(added)} already there")
        return 0
    if cmd == "check-user":
        have = set(load(b).get("permissions", {}).get("deny", []))
        missing = [r for r in load(a)["deny"] if r not in have]
        if missing:
            print(f"WARN  {b}: {len(missing)} personal deny rule(s) missing (e.g. {missing[0]}). Run --user-deny")
            return 1
        print(f"OK    personal deny rules in {b}")
        return 0
    target = Path(b) / ".claude" / "settings.local.json"
    dirs, deny = repo_rules(a)
    if cmd == "repo":
        data = load(target)
        perms = data.setdefault("permissions", {})
        n = len(add_unique(perms.setdefault("additionalDirectories", []), dirs))
        n += len(add_unique(perms.setdefault("deny", []), deny))
        if n:
            save(target, data)
        print(f"OK    {target}: {n} entr(y/ies) added")
        return 0
    if cmd == "check-repo":
        perms = load(target).get("permissions", {})
        missing = [d for d in dirs if d not in perms.get("additionalDirectories", [])]
        missing += [d for d in deny if d not in perms.get("deny", [])]
        if missing:
            print(f"WARN  {target}: missing {missing[0]}. Run --link")
            return 1
        print(f"OK    {Path(b).name}: settings.local.json gives access to {', '.join(Path(d).name for d in dirs)}")
        return 0
    sys.exit(__doc__)


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
