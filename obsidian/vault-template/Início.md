---
type: sistema
summary: "Painel inicial do vault: projetos ativos, tarefas da semana e fontes recentes."
---

# 🏠 Início

> Comece por aqui. Guia: [[Guia de Uso]] · Regras da LLM: [[CLAUDE]] · Catálogo: [[index]] · Histórico: [[log]]

## 📌 Projetos ativos

```base
filters:
  and:
    - 'note.type == "projeto"'
    - 'note.status != "arquivado"'
    - 'note.status != "concluido"'
views:
  - type: table
    name: "Ativos"
    order:
      - file.name
      - note.status
      - note.deadline
      - note.summary
```

## ✅ Tarefas

```base
filters:
  and:
    - 'note.type == "tarefa"'
    - 'note.status != "concluida"'
    - 'note.status != "cancelada"'
views:
  - type: table
    name: "Próximos 7 dias"
    filters:
      and:
        - 'note.due <= today() + "7 days"'
    order:
      - file.name
      - note.project
      - note.priority
      - note.due
  - type: table
    name: "Todas em aberto"
    groupBy:
      property: note.status
      direction: ASC
    order:
      - file.name
      - note.project
      - note.priority
      - note.due
```

## 🆕 Fontes recentes

```base
filters:
  and:
    - 'note.type == "fonte"'
views:
  - type: table
    name: "Recentes"
    limit: 10
    order:
      - file.name
      - note.source_type
      - note.ingested
```
