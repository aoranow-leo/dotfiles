---
type: projeto
status: ativo
owner: Leonardo
start: {{date:YYYY-MM-DD}}
deadline:
tags: []
summary: "Uma frase: o que é este projeto e qual o objetivo."
updated: {{date:YYYY-MM-DD}}
---

# {{title}}

## Objetivo

## Status atual

## Tarefas

```base
filters:
  and:
    - 'note.type == "tarefa"'
    - file.inFolder("Projetos/{{title}}/Tarefas")
views:
  - type: table
    name: "Tarefas deste projeto"
    groupBy:
      property: note.status
      direction: ASC
    order:
      - file.name
      - note.priority
      - note.due
```

## Decisões
<!-- links para Notas/ (decisões, reuniões) -->

## Conhecimento relacionado
<!-- entidades e conceitos relevantes da pasta wiki/ -->

## Histórico
<!-- marcos importantes; a linha do tempo completa fica em [[log]] -->
