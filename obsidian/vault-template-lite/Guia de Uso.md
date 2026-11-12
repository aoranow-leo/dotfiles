---
type: sistema
summary: "Como usar este wiki: o que pedir à LLM e onde cada coisa fica."
---

# Guia de Uso

Este wiki é mantido pela LLM (Claude Code aberto nesta pasta). Você traz as fontes e faz as perguntas; ela escreve, liga e confere as páginas.

## Regras desta máquina

- Sem git e sem sync. O wiki fica só aqui.
- Nada sai desta máquina.
- Sem plugins da comunidade no Obsidian.

## Onde fica cada coisa

| Pasta ou arquivo | O que é | Quem mexe |
|---|---|---|
| `raw/` | fontes como chegaram | você deposita; a LLM só lê |
| `fontes/` | uma página por fonte lida | LLM |
| `wiki/` | uma página por assunto | LLM |
| `notas/` | reuniões e notas com data | LLM |
| `Tarefas.md` | tarefas em aberto | LLM |
| `index.md` | mapa de tudo (gerado) | script |
| `log.md` | o que mudou, mais novo no topo | LLM |
| `CLAUDE.md` | regras que a LLM segue | você |

## O que pedir

1. **Ingerir:** "Coloquei `raw/ata.md`. Lê, me diz os pontos principais e ingere."
2. **Perguntar:** "O que já sei sobre X? Responde com links."
3. **Nota:** "Anota a reunião de hoje: …"
4. **Tarefa:** "Adiciona a tarefa X com prazo sexta." · "Marca X como feita."
5. **Conferir:** "Roda o `scripts/wiki.py` e me diz o que apareceu."

## Conferência

`python3 scripts/wiki.py` regenera o `index.md` e lista o que está errado. `ERRO` a LLM corrige sozinha; `AVISO` ela te conta.

Comece por [[index]]. Tarefas em [[Tarefas]], histórico em [[log]].
