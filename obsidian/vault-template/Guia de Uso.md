# Guia de Uso — Knowledge Base + Projetos com LLM

Este vault é uma **base de conhecimento que se compõe sozinha** e um **rastreador de projetos**, mantidos por uma LLM (Claude Code ou outra). Padrão "LLM Wiki" do Karpathy:

> **Você cuida das fontes, da direção e das boas perguntas. A LLM faz o resto**: resumir, cruzar, arquivar, atualizar referências e manter tudo consistente.

Você quase nunca escreve a wiki à mão. Abra a LLM na pasta do vault de um lado e o Obsidian do outro, e acompanhe as edições.

## Regras desta máquina

- **Sem git e sem sync.** O vault fica só aqui.
- **Nada sai desta máquina.** Não copie conteúdo para fora.
- **Sem plugins da comunidade.** Só os do Obsidian: Bases, Canvas, Templates.

## Como está organizado

| Pasta | O que é | Quem edita |
|---|---|---|
| `Projetos/` | hub de cada projeto, `Tarefas/`, `Notas/` | LLM (você revisa) |
| `raw/` | fontes brutas e imutáveis | você (deposita) |
| `wiki/` | `fontes/`, `entidades/`, `conceitos/`, `sinteses/` | LLM |
| `Bases/` | tabelas dinâmicas | LLM |
| `Templates/` | modelos de página | LLM |
| `_meta/taxonomy.md` | tags e status permitidos | LLM |
| `Início.md` | painel do dia | LLM |
| `index.md` / `log.md` | catálogo / linha do tempo | LLM |
| `CLAUDE.md` | instruções da LLM (em inglês) | LLM/você |

## Primeiro uso

1. Abra esta pasta no Obsidian (*Open folder as vault*).
2. Abra `Início.md` e marque como favorito.
3. Em *Configurações → Sobre*, desligue as atualizações automáticas se a regra da empresa pedir.

## As 5 coisas que você pede à LLM

1. **Ingerir:** *"Coloquei `raw/reunioes/X.md`. Lê, me diz os pontos principais e ingere."*
2. **Perguntar:** *"O que já sei sobre [tema]? Responde com links."*
3. **Projeto:** *"Cria o projeto 'X' — objetivo: …, prazo: …"*
4. **Tarefas/atividade:** *"No projeto X, adiciona as tarefas A (alta, sexta) e B."* · *"Marca A como concluída."*
5. **Lint:** *"Roda um lint: links quebrados, órfãs, contradições, tarefas atrasadas."*

## Boas práticas

- Uma fonte por vez, e revise os resumos.
- Capture rápido em `raw/inbox/`; depois peça para processar.
- Confie nas seções "Lacunas" e "Contra-argumentos".
- Peça lint toda semana ou quinzena.

## Diagramas (sem plugin)

| Quero… | Formato |
|---|---|
| Fluxo, sequência, gantt, ER | Mermaid (nativo) |
| Mapa mental / board de ideias | Canvas (nativo) |
| Arquitetura | SVG ou draw.io gerado pela LLM |

As regras completas que a LLM segue estão em [[CLAUDE]].
