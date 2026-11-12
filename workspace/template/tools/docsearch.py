#!/usr/bin/env python3
"""docsearch.py — ranked full-text search over a Markdown reference clone in refs/.
Python 3.8+, stdlib only (SQLite FTS5). Nothing leaves this machine.

  python3 tools/docsearch.py index  <ref>             build or rebuild the index (about a minute)
  python3 tools/docsearch.py search <ref> <words...>  top 10 pages, best match first
        -n 20            more results
        --area <name>    only one area (first folder under markdown/), e.g. application-development
        --any            match any word (default: all words)
  python3 tools/docsearch.py areas  <ref>             list the areas and how many pages each has

<ref> is a folder name under refs/ (e.g. servicenow-docs). The index lives in refs/.search/<ref>.db.
Works from the workspace root or from inside a repo. Words in "double quotes" are searched as a phrase.
Results print title, path (relative to where you are) and a short snippet; open the file by that path.
"""
import argparse
import os
import re
import sqlite3
import subprocess
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
REFS = ROOT / "refs"
FM_RE = re.compile(r"\A---\n(.*?)\n---\n", re.S)
H1_RE = re.compile(r"^#\s+(.+)$", re.M)
URL_KEYS = ("canonical_url", "canonical", "url", "source_url")


def ref_dir(name):
    d = REFS / name
    if not d.is_dir():
        sys.exit(f"ERROR refs/{name} does not exist. Folders in refs/: "
                 + ", ".join(p.name for p in REFS.iterdir() if p.is_dir() and not p.name.startswith(".")))
    return d


def db_path(name):
    return REFS / ".search" / f"{name}.db"


def head_of(d):
    try:
        return subprocess.run(["git", "-C", str(d), "rev-parse", "HEAD"], capture_output=True,
                              text=True, check=True).stdout.strip()
    except (OSError, subprocess.CalledProcessError):
        return ""


def parse(text):
    meta = {}
    m = FM_RE.match(text)
    body = text
    if m:
        body = text[m.end():]
        for line in m.group(1).splitlines():
            if ":" in line:
                k, v = line.split(":", 1)
                meta[k.strip().lower()] = v.strip().strip("\"'")
    h1 = H1_RE.search(body)
    title = meta.get("title") or (h1.group(1).strip() if h1 else "")
    url = next((meta[k] for k in URL_KEYS if meta.get(k)), "").replace("\\", "")
    return title, url, body


def area_of(rel):
    parts = rel.parts
    if parts and parts[0] == "markdown" and len(parts) > 2:
        return parts[1]
    return parts[0] if len(parts) > 1 else ""


def cmd_index(a):
    d = ref_dir(a.ref)
    db = db_path(a.ref)
    db.parent.mkdir(parents=True, exist_ok=True)
    tmp = db.with_suffix(".tmp")
    if tmp.exists():
        tmp.unlink()
    t0 = time.time()
    con = sqlite3.connect(tmp)
    con.execute("CREATE VIRTUAL TABLE docs USING fts5(title, body, path UNINDEXED, area UNINDEXED, "
                "url UNINDEXED, tokenize='porter unicode61')")
    con.execute("CREATE TABLE meta(k TEXT PRIMARY KEY, v TEXT)")
    n = 0
    for p in sorted(d.rglob("*.md")):
        rel = p.relative_to(d)
        if rel.parts[0].startswith("."):
            continue
        title, url, body = parse(p.read_text(encoding="utf-8", errors="replace"))
        con.execute("INSERT INTO docs VALUES (?,?,?,?,?)",
                    (title or rel.stem, body, rel.as_posix(), area_of(rel), url))
        n += 1
    con.execute("INSERT INTO meta VALUES ('head', ?)", (head_of(d),))
    con.execute("INSERT INTO docs(docs) VALUES ('optimize')")
    con.commit()
    con.close()
    tmp.replace(db)
    print(f"OK    indexed {n} pages of refs/{a.ref} in {time.time() - t0:.0f}s -> {db.relative_to(ROOT)}")
    return 0 if n else 1


def open_db(name):
    db = db_path(name)
    if not db.exists():
        sys.exit(f"ERROR no index for refs/{name}. Run: python3 {os.path.relpath(__file__)} index {name}")
    con = sqlite3.connect(db)
    row = con.execute("SELECT v FROM meta WHERE k='head'").fetchone()
    now = head_of(ref_dir(name))
    if row and now and row[0] != now:
        print(f"WARN  refs/{name} changed since the index was built. "
              f"Run: python3 {os.path.relpath(__file__)} index {name}")
    return con


def fts_query(words, any_word):
    text = " ".join(words)
    phrases = re.findall(r'"([^"]+)"', text)
    rest = re.sub(r'"[^"]+"', " ", text)
    terms = ['"' + ph.replace('"', "") + '"' for ph in phrases]
    terms += ['"' + w.replace('"', "") + '"' for w in re.findall(r"[\w.\-]+", rest)]
    if not terms:
        sys.exit("ERROR empty query")
    return (" OR " if any_word else " AND ").join(terms)


def cmd_search(a):
    con = open_db(a.ref)
    q = fts_query(a.words, a.any)
    sql = ("SELECT title, path, url, snippet(docs, 1, '[', ']', ' … ', 18) FROM docs "
           "WHERE docs MATCH ?" + (" AND area = ?" if a.area else "")
           + " ORDER BY bm25(docs, 10.0, 1.0) LIMIT ?")
    rows, seen = [], set()
    # Pages with the words side by side (as a phrase) first, then the rest.
    words = " ".join(a.words)
    if not a.any and '"' not in words and len(re.findall(r"[\w.\-]+", words)) > 1:
        phrase = '"' + " ".join(re.findall(r"[\w.\-]+", words)) + '"'
        tries = [phrase, q]
    else:
        tries = [q]
    for qq in tries:
        for r in con.execute(sql, [qq] + ([a.area] if a.area else []) + [a.n]):
            if r[1] not in seen and len(rows) < a.n:
                seen.add(r[1]); rows.append(r)
    total = con.execute("SELECT count(*) FROM docs WHERE docs MATCH ?"
                        + (" AND area = ?" if a.area else ""), [q] + ([a.area] if a.area else [])).fetchone()[0]
    print(f"{total} page(s) match {q}" + (f" in area {a.area}" if a.area else "") + f"; showing {len(rows)}")
    for i, (title, path, url, snip) in enumerate(rows, 1):
        shown = os.path.relpath(REFS / a.ref / path)
        print(f"\n{i}. {title}\n   {shown}" + (f"\n   {url}" if url else ""))
        print("   " + " ".join(snip.split())[:300])
    return 0


def cmd_areas(a):
    con = open_db(a.ref)
    for area, n in con.execute("SELECT area, count(*) FROM docs GROUP BY area ORDER BY 2 DESC"):
        print(f"{n:6d}  {area or '(root)'}")
    return 0


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = p.add_subparsers(dest="cmd", required=True)
    s = sub.add_parser("index"); s.add_argument("ref")
    s = sub.add_parser("search"); s.add_argument("ref"); s.add_argument("words", nargs="+")
    s.add_argument("-n", type=int, default=10); s.add_argument("--area"); s.add_argument("--any", action="store_true")
    s = sub.add_parser("areas"); s.add_argument("ref")
    a = p.parse_args()
    return {"index": cmd_index, "search": cmd_search, "areas": cmd_areas}[a.cmd](a)


if __name__ == "__main__":
    sys.exit(main())
