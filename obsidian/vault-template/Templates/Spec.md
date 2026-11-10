---
type: spec
status: rascunho            # rascunho | clarificado | projetado | pronto | implementado | superado
project:                   # ex.: "[[Nome do Projeto]]"
feature_ids: []            # F-ids da fatia — ex.: [F-001, F-002]
clarificacoes_resolvidas: false   # gate: resolver antes de implementar
summary: "Uma frase: o que esta fatia entrega e por quê."
tags: []
impl_repo:                 # preenchido no export — ex.: github.com/org/repo
impl_path:                 # ex.: docs/specs/001-fatia/spec.md
impl_pr:                   # ex.: #142
impl_status: nao-iniciado  # nao-iniciado | exportado | implementado
created: {{date:YYYY-MM-DD}}
updated: {{date:YYYY-MM-DD}}
---

# {{title}}

> Spec **autorada no vault** (fonte de autoria). Unidade = **primeira fatia demoável** de um projeto. Fluxo: [[CLAUDE]] §10.

## Contexto
> Sem detalhe de implementação aqui.

- **Problema / usuários** (1 parágrafo, sem tech): …
- **Arquétipo + stack:** `poc | internal` · compute / iac / lang · ai_features: sim/não · eval: … *(1 linha)*
- **Primeira fatia demoável** (o que dá pra mostrar em ~1 semana): …
- **Fora de escopo:** …
- **A esclarecer (GATE):**
  - [PRECISA CLARIFICAR: dúvida de problema/fatia/stack. Resolver ANTES de implementar.]

## Features da fatia
> Os EARS por feature são a **fonte** da `verification`.

| F-id | Prioridade | Comportamento visível (1 linha) | Verification (rodável) |
|------|-----------|----------------------------------|------------------------|
| F-001 | 1 | … | … |

### F-001 — {nome}
**Critérios de aceite (EARS):**
- 1.1 QUANDO `<gatilho>` O SISTEMA DEVE `<resposta>`
- 1.2 SE `<gatilho>` ENTÃO O SISTEMA DEVE `<resposta>`

<!-- Repita o bloco "### F-NNN" por feature. Numere os critérios X.Y onde X = índice da feature. -->

## Design — rascunho
> Só **decisões**, compacto. Linke termos de domínio a `[[wiki/entidades/...]]` inline.

- **Arquitetura:** 1 diagrama + componentes-chave.
  ```mermaid
  graph TD
    A[Client] --> B[Entry] --> C[Compute] --> D[(Data)]
  ```
- **Modelo de dados:** entidades-chave (só os campos que importam).
- **Acesso:** papéis + regras não-óbvias *(3-5 linhas; ex.: "user vê só o próprio X; admin vê tudo; não-autenticado → 401")*.
- **API:** endpoints principais (request/response só onde não for óbvio).
- **Restrições:** segurança / performance / dependências *(1 linha cada)*.

## Changelog
- {{date:YYYY-MM-DD}} — rascunho inicial.
