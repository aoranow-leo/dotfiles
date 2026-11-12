# dotfiles

Meu terminal em qualquer Mac: zsh sem framework, Starship, fzf, atuin, zoxide, eza, bat, ripgrep, fd, delta.

## Instalar

```sh
git clone https://github.com/aoranow-leo/dotfiles.git ~/dotfiles
~/dotfiles/install.sh
```

Depois:

1. Abrir um terminal novo.
2. No terminal, escolher a fonte **MesloLGS Nerd Font**.
3. Se a máquina for nova: `git config --global user.name "..."` e `git config --global user.email "..."`.

## Atualizar

```sh
cd ~/dotfiles && git pull && ./install.sh
```

Os arquivos são links, então um `git pull` já muda o `.zshrc`. O `install.sh` só precisa rodar de novo quando o `Brewfile` mudar.

## O que tem

| Arquivo | Vira | O quê |
|---|---|---|
| `zsh/zshrc` | `~/.zshrc` (link) | shell, histórico, teclas, aliases, plugins |
| `atuin/config.toml` | `~/.config/atuin/config.toml` (link) | histórico só local (sem sync, sem update check) |
| `git/gitconfig` | `include.path` no `~/.gitconfig` | delta, zdiff3, `push.autoSetupRemote` |
| `Brewfile` | `brew bundle` | tudo que é instalado |

O que já existir vira `<arquivo>.bak.<data>`.

## Por máquina

- `~/.zshrc.local`: PATH extra, aliases e ferramentas só daquela máquina. É carregado no fim do `.zshrc` e não fica no repo.
- `user.name` e `user.email` do git ficam no `~/.gitconfig` da máquina.
- `SKIP_BREW=1 ./install.sh`: só faz os links e o git, para máquinas onde não dá para instalar pelo Homebrew.

## Teclas

| Tecla | Faz |
|---|---|
| `Ctrl+R` | busca no histórico (atuin) |
| `↑` / `↓` | histórico que começa com o que já foi digitado |
| `Ctrl+T` | escolher arquivo (fzf) |
| `Alt+C` | entrar numa pasta (fzf) |
| `z <parte do nome>` | pular para uma pasta já visitada (zoxide) |

## Obsidian (wiki local mantida por LLM)

Dois esqueletos de vault no padrão LLM Wiki, sem conteúdo:

| Template | Para quê | O que tem |
|---|---|---|
| `obsidian/vault-template/` | vários projetos, modelo grande | 8 tipos de página, tarefas, specs, Bases, taxonomia |
| `obsidian/vault-template-lite/` | um wiki simples em inglês, modelo menor (Sonnet/Haiku) | 3 tipos de página (`wiki/`, `sources/`, `notes/`), `Tasks.md` e `scripts/wiki.py` |

```sh
~/dotfiles/obsidian/new-vault.sh ~/Documents/Wiki            # completo
~/dotfiles/obsidian/new-vault.sh --lite ~/Documents/Wiki     # simples
~/dotfiles/obsidian/new-vault.sh --update ~/Documents/Wiki   # só troca os arquivos de sistema (detecta qual é)
```

No lite, a LLM roda `python3 scripts/wiki.py` depois de cada mudança: ele regenera o `index.md` e lista o que está errado (link quebrado, frontmatter, log sem entrada). Precisa só de Python 3.8+, sem pacotes.

O vault é uma cópia, não um link: o conteúdo nunca volta para este repo. Nenhum dos dois usa git, sync nem plugins da comunidade.

## Workspace (repos + wiki local na mesma pasta)

Repos de cliente, wiki local, guias e docs de referência lado a lado, sem misturar:

```sh
~/dotfiles/workspace/new-workspace.sh --lite ~/work/projeto    # raiz + wiki/ (lite) + guides/ + refs/ + tools/
git clone <url> ~/work/projeto/<nome>                          # cada repo dentro da raiz
~/dotfiles/workspace/new-workspace.sh --link ~/work/projeto    # liga cada repo às pastas vizinhas
~/dotfiles/workspace/new-workspace.sh --user-deny              # seus bloqueios pessoais (uma vez por máquina)
~/dotfiles/workspace/new-workspace.sh --check ~/work/projeto   # confere tudo
cd ~/work/projeto/<repo> && claude                             # o Claude abre DENTRO do repo
```

Cada regra fica num lugar só, e as listas de allow/ask/deny dos níveis se somam (deny ganha de ask, que ganha de allow):

| Onde | O quê | Quem mantém |
|---|---|---|
| `<repo>/.claude/settings.json` | regras do cliente | o cliente, pelo git |
| `~/.claude/settings.json` | seus bloqueios (`user-deny.json`: SDK install/deploy/exec/cicd/auth, `git init`, `gh pr merge`, `~/.now-sdk/`) | `--user-deny`, que soma sem apagar nada |
| `<repo>/.claude/settings.local.json` | acesso a `../wiki`, `../guides`, `../refs`, `../tools` e deny de edição em `refs/` | `--link`; fica fora dos commits (`.git/info/exclude`) |
| `CLAUDE.md` da raiz | papel de cada pasta; o wiki faz parte de cada execução | `--update` |

- O Claude Code só lê o `.claude/settings.json` da pasta onde abre, e lê os `CLAUDE.md` das pastas acima. Abrindo no repo, valem as regras do cliente + as suas, e o `CLAUDE.md` da raiz entra junto.
- A raiz **não é git** e o wiki também não: um `git add` no lugar errado falha.
- O `CLAUDE.md` do wiki não carrega sozinho quando o Claude abre no repo; o `CLAUDE.md` da raiz manda ler `../wiki/CLAUDE.md` antes de registrar algo.

### Documentação de referência (refs/)

`refs/` guarda clones só de leitura (o `--link` põe deny de edição; rode o `--link` de novo depois de criar `refs/`). Para a doc oficial do ServiceNow ([ServiceNowDocs](https://github.com/ServiceNow/ServiceNowDocs), um branch por release):

```sh
~/dotfiles/workspace/add-servicenow-docs.sh ~/work/projeto                 # australia, áreas de plataforma/dev/CSM
~/dotfiles/workspace/add-servicenow-docs.sh --release brazil --areas all ~/work/projeto
~/dotfiles/workspace/add-servicenow-docs.sh --update ~/work/projeto        # versão nova + reindexa
python3 ../tools/docsearch.py search servicenow-docs ui policy              # de dentro do repo: 10 páginas mais relevantes
python3 ../tools/docsearch.py search servicenow-docs "view rule" --area platform-user-interface
```

- Clone raso e esparso: só a release e as áreas pedidas (padrão ≈ 16 mil páginas, ~140 MB + ~120 MB de índice; tudo ≈ 51 mil, ~300 MB + índice).
- `docsearch.py` é SQLite FTS5 (BM25) do próprio Python: índice local de ~1 min, nada sai da máquina. Devolve título, caminho, URL e um trecho, em vez das milhares de linhas de um grep.

## Regra

Nada de segredo aqui: o repo é público. Token, chave e `.env` ficam fora.
