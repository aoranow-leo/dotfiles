# CLAUDE.md — Wiki & Project schema

> Schema for an LLM-maintained knowledge base + project tracker ("LLM Wiki" pattern, Karpathy).
> Written in **English on purpose** (the human reads PT-BR content; the agent reads these instructions in EN).
> The human curates sources and asks questions. **You (the agent) do all the bookkeeping.**

---

## 0. Prime directives

1. **You write the wiki; the human reads it.** The human sources, directs and asks. You summarize, cross-reference, file, merge and keep everything consistent. Touch 10–15 pages in one pass if a source warrants it.
2. **Raw sources are immutable.** Read from `raw/`; never edit it.
3. **Compile knowledge once, then keep it current.** Update living pages (entities/concepts) on re-ingest — merge, never blindly overwrite.
4. **No blind links, no orphans.** Every `[[wikilink]]` must resolve to a page that exists (or that you create in the same pass). Weave back-links both directions.
5. **Discuss before you write (on ingest).** Surface key takeaways to the human first. This catches hallucination early.
6. **Merge, don't duplicate.** Never create `rag-2.md`.
7. **Always update `index.md` and append to `log.md`** when you change the wiki.
8. **When unsure, say so.** Use `confidence` / `provenance` and `## Lacunas`.
9. **Use agent-side tooling, not Obsidian plugins.** Emit **Mermaid** (native) or generate raw artifacts directly. Never assume a community plugin is installed.

### 0.1 Local policy (this machine) — edit if the situation differs
- **No git, no remote, no sync — in this folder.** Do not run `git init` here, do not enable Obsidian Sync/Publish, do not add any cloud sync. The vault lives only on this machine. If this vault sits next to Git repositories in a shared workspace, those repositories keep their normal Git workflow; this rule covers only the vault, and vault content is never copied into them.
- **Content never leaves this machine.** Don't upload, paste or send vault content to external services. MCP servers / connectors only if the organization provides them.
- **No business data.** Never store business records, personal data, credentials or tokens here. Record metadata, decisions and what you learned, not the data itself.
- **No community plugins.** Only core plugins (Bases, Canvas, Templates, Properties, Daily notes…).
- Never rely on an auto-formatter that rewrites files on save. Frontmatter consistency is the LINT operation (§4).

---

## 1. Language & naming

- Page bodies, summaries, titles, the user guide → **Portuguese (PT-BR)**. This schema → English.
- Frontmatter keys → English (`type`, `status`, `summary`…). Controlled values → Portuguese, lowercase, accent-free (`ativo`, `concluida`, `extraido`).
- File names: human-readable Title Case (`Fulano de Tal.md`). Avoid `# | ^ : [ ] %% / \`.
- Dates: ISO `YYYY-MM-DD`.
- **Links inside frontmatter MUST be quoted**: `project: "[[Meu Projeto]]"`.
- Tags: YAML list, without `#`, from [[taxonomy]] (`_meta/taxonomy.md`). Don't invent synonyms — add to the taxonomy in the same pass.

---

## 2. Architecture

```
<vault>/
├── CLAUDE.md  Guia de Uso.md  Início.md  index.md  log.md
├── Projetos/<Projeto>/{<Projeto>.md, Tarefas/, Notas/, Specs/}
├── raw/       # IMMUTABLE sources: inbox/ artigos/ reunioes/ threads/ pdfs/ assets/
├── wiki/      # fontes/ entidades/ conceitos/ sinteses/
├── Bases/     # Projetos.base, Tarefas.base, Fontes.base
├── Templates/
└── _meta/taxonomy.md
```

`Projetos/` tracks *what you're doing*; `wiki/` accumulates *what you know*. They cross-reference via `[[wikilinks]]`.

---

## 3. Page types & frontmatter

Every page starts with `---` on line 1. System files (`Início.md`, `index.md`, `log.md`) use `type: sistema` + `summary` only.

| type | Folder | Required fields | Body |
|---|---|---|---|
| `projeto` | `Projetos/<P>/<P>.md` | `status` (ativo·pausado·concluido·arquivado), `start`, `summary`, `updated` | Objetivo · Status atual · Tarefas (embedded Base) · Decisões · Conhecimento relacionado · Histórico |
| `tarefa` | `Projetos/<P>/Tarefas/` | `status` (a-fazer·fazendo·bloqueada·concluida·cancelada), `priority` (1–3), `project`, `created`, `updated` | description · Subtarefas · Notas |
| `nota` | `Projetos/<P>/Notas/` | `kind` (decisao·reuniao·ideia·geral), `project`, `date`, `summary` | meetings: Participantes · Discussão · Decisões · Ações |
| `fonte` | `wiki/fontes/` | `source_type`, `ingested`, `summary` | Páginas tocadas · Takeaways · Citações |
| `entidade` | `wiki/entidades/` | `kind`, `summary`, `confidence`, `provenance`, `explored: false` | Resumo · Detalhes · Lacunas |
| `conceito` | `wiki/conceitos/` | `summary`, `confidence`, `provenance`, `explored: false` | Resumo · Detalhes · Contra-argumentos · Lacunas |
| `sintese` | `wiki/sinteses/` | `question`, `summary` | answer with `[[link]]` citations |
| `spec` | `Projetos/<P>/Specs/` | `status`, `project`, `summary`, `clarificacoes_resolvidas` | Requisitos (EARS) · Design · Tarefas · Changelog |

Use the files in `Templates/` — they hold the full frontmatter. Controlled values live in [[taxonomy]].

---

## 4. Operations

### INGEST
1. Read the source (from `raw/`, pasted text, or a link). Never modify raw files.
2. **Discuss** key takeaways with the human before writing.
3. Create `wiki/fontes/<Título>.md`.
4. For each entity/concept touched: merge if it exists (note contradictions, `provenance: ambiguo`), else create from template.
5. Weave `[[wikilinks]]` both ways; link unlinked mentions of existing pages.
6. Fill the source's `## Páginas tocadas` (`(criada)` / `(atualizada)`).
7. Rebuild `index.md`, append to `log.md`.
8. If the source belongs to a project, link it from the hub and create/update tasks.

### QUERY
1. Read `index.md`, then scan `summary` fields; open only relevant bodies.
2. Answer with `[[wikilink]]` citations.
3. If reusable, offer to file it in `wiki/sinteses/`, then update `index.md` + `log.md`.

### LINT (on request)
Report broken links, orphans, contradictions, stale claims, missing pages for repeated concepts, malformed frontmatter, non-taxonomy tags, provenance drift, stale `ativo` projects, overdue open tasks, tasks without `project`. Auto-fix only safe things (links, frontmatter, tags); confirm merges/deletions. Log the pass.

### PROJECT ops
- New project: `Projetos/<Nome>/<Nome>.md` from the template + `Tarefas/` and `Notas/`; embedded Base pointing at the project's `Tarefas` folder (§6).
- Status changes: edit `status` + `updated`; decisions/meetings become `nota` pages.
- Tasks: create from template; on completion `status: concluida` + `updated`.

---

## 5. `index.md` and `log.md`

- `index.md` — catalog rebuilt on every wiki change, by category (Projetos, Entidades, Conceitos, Sínteses, Fontes). Line: `- [[Página]] — resumo`.
- `log.md` — append-only, newest at the **top**. Prefix: `## [YYYY-MM-DD] <op> | <descrição>`, `<op>` ∈ `ingest | query | lint | projeto | tarefa | spec`. Touched pages: `+` created, `~` updated, `-` removed.

---

## 6. Bases (.base) — syntax cheat-sheet

- Top-level keys: `filters`, `formulas`, `properties`, `summaries`, `views`. Embedded in a note via a ` ```base ` fence (singular).
- Filters: `'note.status != "arquivado"'` (single-quote lines with inner quotes), `file.inFolder("Projetos/X/Tarefas")`, `file.hasTag("x")`; nest with `and:` / `or:` / `not:`.
- Dates: `today()`, `now()`, `'note.due <= today() + "7 days"'`. Units `y M w d h m s` (`M`=month, `m`=minute).
- Views: `type` ∈ `table | cards | list | map`, plus `name`, `limit`, `groupBy: {property, direction}`, `filters`, `order`.
- There is **no `sort:` key**; column widths are set in the UI.

Embedded tasks Base in a project hub:
````
```base
filters:
  and:
    - 'note.type == "tarefa"'
    - file.inFolder("Projetos/<Projeto>/Tarefas")
views:
  - type: table
    name: "Tarefas deste projeto"
    order: [file.name, note.status, note.priority, note.due]
```
````

---

## 7. Anti-patterns

Sprawl/over-creation · hallucination treated as truth · false coverage (hide gaps) · inconsistent terminology · monolithic files · missing `summary` · over-engineering early.

---

## 8. Session start checklist

1. Skim the top of `log.md`. 2. Read `index.md`. 3. For a query, scan `summary` fields first. 4. For an ingest, confirm takeaways first. 5. After any change: `index.md`, `log.md`, no broken/orphan links.

---

## 9. Visual outputs (no plugins)

| Need | Format |
|---|---|
| Flow / sequence / gantt / ER / state / class | **Mermaid** inline (native). Mermaid `mindmap`/`timeline` do **not** render in Obsidian. |
| Mind map / idea board | **Canvas** (`.canvas` JSON: `nodes` + `edges`), or a Mermaid flowchart |
| Architecture / formal diagrams | draw.io / SVG generated by the agent, saved next to the page that uses it |
| Slides | Markdown outline; export elsewhere if needed |

Keep one flow per diagram; store it on the page it explains. Never use AI raster images for technical diagrams.

---

## 10. Specs (authoring here → implementation in a repo)

- One `spec` note per feature in `Projetos/<P>/Specs/`. Body: **Requisitos** (user stories + EARS: `O SISTEMA DEVE…`, `QUANDO…`, `ENQUANTO…`, `SE… ENTÃO…`, `ONDE…`; no tech stack) → **Design** → **Tarefas** (each traced `_Requisitos: X.Y_`) → **Changelog**.
- Mark unknowns `[PRECISA CLARIFICAR: …]`. Status `rascunho → clarificado → projetado → pronto`. Don't hand off while markers remain.
- Hand-off: copy the spec into the repo (`docs/specs/<NNN-feature>/spec.md`) with a header (`spec_source`, `exported`, `status`); the repo copy is the implementation truth on its branch. When the vault spec changes, re-export to the same path and open a task to reconcile — never edit code silently.
