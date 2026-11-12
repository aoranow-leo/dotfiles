#!/usr/bin/env python3
"""Regenera o index.md e confere o wiki. Rode depois de qualquer mudança.

    python3 scripts/wiki.py

ERRO  = precisa corrigir (o comando sai com código 1 enquanto houver algum).
AVISO = conte para a pessoa; corrija se fizer sentido.

Só stdlib, Python 3.8+. A única coisa que este script escreve é o index.md.
"""
from __future__ import annotations

import datetime as dt
import re
import sys
import unicodedata
from collections import defaultdict
from pathlib import Path

VAULT = Path(__file__).resolve().parent.parent
FOLDERS = {"wiki": "pagina", "fontes": "fonte", "notas": "nota"}
REQUIRED = {
    "pagina": ["summary", "updated"],
    "fonte": ["summary", "origin", "ingested"],
    "nota": ["summary", "date"],
}
DATE_FIELDS = ("updated", "ingested", "date")
SUMMARY_MAX = 200
PAGE_LINES_MAX = 200
INDEX_LINES_MAX = 200
NO_LINK_CHECK = {"CLAUDE.md", "log.md", "index.md"}  # o log guarda história; o index é gerado

LINK_RE = re.compile(r"!?\[\[([^\]\n]+?)\]\]")
FENCE_RE = re.compile(r"^(```|~~~).*?^\1[^\n]*$", re.S | re.M)
INLINE_CODE_RE = re.compile(r"`[^`\n]*`")
DATE_RE = re.compile(r"^\d{4}-\d{2}-\d{2}$")
LOG_RE = re.compile(r"^- (\d{4}-\d{2}-\d{2}) ", re.M)
TASK_RE = re.compile(r"^\s*- \[ \] (.*?)\(prazo: (\d{4}-\d{2}-\d{2})\)", re.M)


def nfc(s: str) -> str:
    """macOS grava nomes de arquivo em NFD; o texto das páginas costuma estar em NFC."""
    return unicodedata.normalize("NFC", s)


def split_frontmatter(text: str):
    if not text.startswith("---\n"):
        return None, text
    end = text.find("\n---", 4)
    if end == -1:
        return None, text
    return text[4:end], text[end + 4:]


def parse_scalar(v: str):
    v = v.strip()
    if len(v) >= 2 and v[0] == v[-1] and v[0] in "\"'":
        return v[1:-1]
    if v.startswith("[") and v.endswith("]"):
        inner = v[1:-1].strip()
        if not inner:
            return []
        return [parse_scalar(x) for x in re.split(r",\s*(?=(?:[^\"]*\"[^\"]*\")*[^\"]*$)", inner)]
    return v


def parse_frontmatter(raw: str) -> dict:
    """Subconjunto de YAML usado aqui: `chave: valor`, lista inline e lista em bloco."""
    out: dict = {}
    key = None
    for line in raw.splitlines():
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        m = re.match(r"^([A-Za-z_][\w-]*):\s*(.*)$", line)
        if m:
            key, val = m.group(1), m.group(2)
            out[key] = parse_scalar(val) if val.strip() else None
        elif key and re.match(r"^\s*-\s+", line):
            if not isinstance(out.get(key), list):
                out[key] = []
            out[key].append(parse_scalar(re.sub(r"^\s*-\s+", "", line)))
    return out


def link_targets(text: str) -> list:
    text = INLINE_CODE_RE.sub("", FENCE_RE.sub("", text))
    out = []
    for m in LINK_RE.finditer(text):
        t = m.group(1).split("|")[0].split("#")[0].rstrip("\\").strip()
        if t:
            out.append(nfc(t))
    return out


def skipped(rel: Path) -> bool:
    return any(part.startswith(".") or ".bak." in part for part in rel.parts)


def one_line(s) -> str:
    return re.sub(r"\s+", " ", str(s or "")).strip()


def render_index(pages: list) -> str:
    def of(typ, key, reverse=False):
        return sorted((p for p in pages if p["type"] == typ), key=key, reverse=reverse)

    def line(p, date_field=None):
        date = p["fm"].get(date_field) if date_field else None
        desc = one_line(p["fm"].get("summary"))
        return "- " + (f"{date} " if date else "") + f"[[{p['name']}]]" + (f" — {desc}" if desc else "")

    by_name = lambda p: p["name"].lower()
    paginas = of("pagina", by_name)
    notas = of("nota", lambda p: (str(p["fm"].get("date") or ""), by_name(p)), reverse=True)
    fontes = of("fonte", lambda p: (str(p["fm"].get("ingested") or ""), by_name(p)), reverse=True)
    out = [
        "---", "type: sistema",
        'summary: "Mapa do wiki, gerado por scripts/wiki.py a partir do summary de cada página."',
        "---", "", "# index", "",
        "> Gerado. Não edite: mude o `summary` da página e rode `python3 scripts/wiki.py`.",
        "> Tarefas: [[Tarefas]] · Histórico: [[log]] · Como usar: [[Guia de Uso]]", "",
        f"## Páginas ({len(paginas)})", *[line(p) for p in paginas], "",
        f"## Notas ({len(notas)})", *[line(p, "date") for p in notas], "",
        f"## Fontes ({len(fontes)})", *[line(p, "ingested") for p in fontes], "",
    ]
    return "\n".join(out)


def main() -> int:
    today = dt.date.today()
    erros, avisos = [], []

    files = [p for p in VAULT.rglob("*") if p.is_file() and not skipped(p.relative_to(VAULT))]
    md = sorted(p for p in files if p.suffix == ".md")

    # Um link resolve como no Obsidian: pelo nome do arquivo ou pelo caminho, com ou sem .md.
    names = defaultdict(list)
    for p in files:
        rel = p.relative_to(VAULT)
        keys = {rel.as_posix(), p.name}
        if p.suffix == ".md":
            keys |= {p.stem, rel.with_suffix("").as_posix()}
        for k in keys:
            names[nfc(k).lower()].append(p)
    if not names.get("index"):  # o index.md é escrito no fim desta execução
        names["index"].append(VAULT / "index.md")

    texts = {p: p.read_text(encoding="utf-8", errors="replace") for p in md}
    pages = []
    inbound = defaultdict(set)

    for p in md:
        rel = p.relative_to(VAULT)
        srel = nfc(rel.as_posix())
        top = rel.parts[0]
        if top in {"raw", "scripts"}:
            continue
        text = texts[p]
        raw_fm, _ = split_frontmatter(text)
        fm = parse_frontmatter(raw_fm) if raw_fm is not None else None

        if rel.name not in NO_LINK_CHECK:
            for t in link_targets(text):
                hit = names.get(t.lower())
                if not hit:
                    erros.append(f"{srel}: o link [[{t}]] não aponta para nada → crie a página ou tire o link")
                for h in hit or []:
                    if h != p:
                        inbound[h].add(p)

        if top not in FOLDERS:
            continue
        typ = FOLDERS[top]
        if fm is None:
            erros.append(f"{srel}: sem frontmatter → a linha 1 tem de ser `---` (modelo no CLAUDE.md)")
            continue
        raw_fm = raw_fm or ""
        pages.append({"path": p, "rel": srel, "name": nfc(p.stem), "type": typ, "fm": fm})
        if fm.get("type") != typ:
            erros.append(f"{srel}: `type: {fm.get('type')}` → em {top}/ o certo é `type: {typ}`")
        missing = [k for k in REQUIRED[typ] if fm.get(k) in (None, "", [])]
        if missing:
            erros.append(f"{srel}: falta preencher {', '.join(missing)} no frontmatter")
        for field in DATE_FIELDS:
            v = fm.get(field)
            if v not in (None, "") and not DATE_RE.match(str(v)):
                erros.append(f"{srel}: `{field}: {v}` → use a data como AAAA-MM-DD")
            elif field != "date" and str(v or "") > today.isoformat():
                erros.append(f"{srel}: `{field}: {v}` está no futuro → hoje é {today}")
        unquoted = re.search(r"^[\w-]+:\s*\[\[", raw_fm, re.M) or re.search(r"^\s*-\s+\[\[", raw_fm, re.M)
        if unquoted:
            erros.append(f"{srel}: link sem aspas no frontmatter → escreva \"[[Nome]]\"")
        summary = one_line(fm.get("summary"))
        if len(summary) > SUMMARY_MAX:
            erros.append(f"{srel}: summary com {len(summary)} caracteres → corte para uma frase de até {SUMMARY_MAX}")
        if typ == "pagina":
            sources = fm.get("sources")
            sources = [sources] if isinstance(sources, str) else (sources or [])
            if not sources:
                avisos.append(f"{srel}: `sources` vazio → de onde veio esta página?")
            for s in [] if unquoted else sources:
                if not LINK_RE.search(str(s)):
                    erros.append(f"{srel}: item de `sources` não é link ({s}) → use \"[[Nome da fonte ou nota]]\"")
        if typ == "fonte":
            origin = str(fm.get("origin") or "")
            if origin.startswith("raw/") and not (VAULT / origin).exists() and not (VAULT / nfc(origin)).exists():
                if nfc(origin).lower() not in names:
                    erros.append(f"{srel}: `origin: {origin}` → esse arquivo não existe em raw/")
        if text.count("\n") + 1 > PAGE_LINES_MAX:
            avisos.append(f"{srel}: {text.count(chr(10)) + 1} linhas → divida em páginas menores")

    # Nomes repetidos deixam o [[link]] ambíguo.
    seen = defaultdict(list)
    for pg in pages:
        seen[pg["name"].lower()].append(pg["rel"])
    for rels in seen.values():
        if len(rels) > 1:
            erros.append(f"{' e '.join(sorted(rels))}: mesmo nome de arquivo → junte numa página só ou renomeie")

    system = {VAULT / "index.md", VAULT / "log.md"}
    for pg in pages:
        refs = inbound[pg["path"]] - system
        if pg["type"] == "pagina" and not refs:
            avisos.append(f"{pg['rel']}: nenhuma outra página linka para esta → linke de uma página relacionada")
        if pg["type"] == "fonte" and not refs:
            avisos.append(f"{pg['rel']}: nenhuma página usa esta fonte → cite em `sources` ou no texto de uma página")

    # Arquivo em raw/ que nenhuma fonte ou página menciona = ainda não foi ingerido.
    outside_raw = [nfc(t) for p, t in texts.items() if p.relative_to(VAULT).parts[0] != "raw"]
    for p in files:
        rel = p.relative_to(VAULT)
        if rel.parts[0] == "raw" and not any(nfc(p.stem) in t for t in outside_raw):
            avisos.append(f"{nfc(rel.as_posix())}: ainda não foi ingerido (nenhuma página menciona)")

    # O log tem de acompanhar a última mudança.
    log_path = VAULT / "log.md"
    log_dates = LOG_RE.findall(log_path.read_text(encoding="utf-8")) if log_path.exists() else []
    changed = [str(pg["fm"].get(f)) for pg in pages for f in ("updated", "ingested")
               if DATE_RE.match(str(pg["fm"].get(f) or "")) and str(pg["fm"].get(f)) <= today.isoformat()]
    if not log_path.exists():
        erros.append("log.md: não existe → crie com uma linha `- AAAA-MM-DD op: descrição`")
    elif changed and (not log_dates or max(changed) > max(log_dates)):
        erros.append(f"log.md: há página alterada em {max(changed)} e nenhuma linha do log com essa data → "
                     f"acrescente no topo `- {max(changed)} op: descrição`")

    tasks = VAULT / "Tarefas.md"
    if tasks.exists():
        for what, due in TASK_RE.findall(texts.get(tasks, "")):
            if due < today.isoformat():
                avisos.append(f"Tarefas.md: atrasada desde {due}: {one_line(what)}")

    index_path = VAULT / "index.md"
    index = render_index(pages)
    if index.count("\n") + 1 > INDEX_LINES_MAX:
        avisos.append(f"index.md: {index.count(chr(10)) + 1} linhas → o wiki cresceu; avise a pessoa para reorganizar")
    index_changed = not index_path.exists() or index_path.read_text(encoding="utf-8") != index
    if index_changed:
        index_path.write_text(index, encoding="utf-8")

    count = lambda t: sum(1 for pg in pages if pg["type"] == t)
    print(f"wiki.py {today} · {count('pagina')} páginas · {count('nota')} notas · {count('fonte')} fontes")
    print("index.md: " + ("regenerado" if index_changed else "sem mudança"))
    for e in erros:
        print("ERRO  " + e)
    for a in avisos:
        print("AVISO " + a)
    if erros:
        print(f"Resultado: {len(erros)} erro(s), {len(avisos)} aviso(s). Corrija os erros e rode de novo.")
        return 1
    print(f"Resultado: OK, 0 erros, {len(avisos)} aviso(s).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
