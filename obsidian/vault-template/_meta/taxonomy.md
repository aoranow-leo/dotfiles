# Taxonomy — vocabulário controlado

Mantido pela LLM. Antes de criar uma tag ou um valor de status novo, confira aqui. Se faltar, **adicione aqui na mesma passada**; não invente sinônimos soltos.

## Valores controlados (frontmatter)

| Campo | Onde | Valores |
|---|---|---|
| `type` | todas | `projeto` · `tarefa` · `nota` · `fonte` · `entidade` · `conceito` · `sintese` · `spec` · `sistema`* |
| `status` | projeto | `ativo` · `pausado` · `concluido` · `arquivado` |
| `status` | tarefa | `a-fazer` · `fazendo` · `bloqueada` · `concluida` · `cancelada` |
| `status` | spec | `rascunho` · `clarificado` · `projetado` · `pronto` · `implementado` · `superado` |
| `impl_status` | spec | `nao-iniciado` · `exportado` · `implementado` · `divergente` |
| `priority` | tarefa | `1` (baixa) · `2` (média) · `3` (alta) — número |
| `kind` | nota | `decisao` · `reuniao` · `ideia` · `geral` |
| `kind` | entidade | `pessoa` · `organizacao` · `produto` · `ferramenta` · `cliente` · `lugar` |
| `source_type` | fonte | `artigo` · `reuniao` · `thread` · `pdf` · `nota` · `web` · `repo` · `documento` |
| `confidence` | wiki | `alta` · `media` · `baixa` · `incerta` |
| `provenance` | wiki | `extraido` · `inferido` · `ambiguo` |
| `explored` | wiki | `true` / `false` (só revisão humana seta `true`) |

> Valores em minúsculas, sem acento. Datas em `YYYY-MM-DD`.
> \* `sistema` é só para [[Início]], [[index]] e [[log]].

## Tags temáticas (lista, sem `#`)

Crescem com o uso — registre aqui as reutilizáveis.

- `trabalho` · `pesquisa` · `aprendizado`
- `arquitetura` · `infra` · `seguranca` · `documentacao` · `agentes` · `llm`

Use `/` para aninhar quando fizer sentido (ex.: `pesquisa/llm`).
