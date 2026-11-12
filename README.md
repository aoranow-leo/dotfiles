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
| `obsidian/vault-template-lite/` | um wiki simples, modelo menor (Sonnet/Haiku) | 3 tipos de página (`wiki/`, `fontes/`, `notas/`), `Tarefas.md` e `scripts/wiki.py` |

```sh
~/dotfiles/obsidian/new-vault.sh ~/Documents/Wiki            # completo
~/dotfiles/obsidian/new-vault.sh --lite ~/Documents/Wiki     # simples
~/dotfiles/obsidian/new-vault.sh --update ~/Documents/Wiki   # só troca os arquivos de sistema (detecta qual é)
```

No lite, a LLM roda `python3 scripts/wiki.py` depois de cada mudança: ele regenera o `index.md` e lista o que está errado (link quebrado, frontmatter, log sem entrada). Precisa só de Python 3.8+, sem pacotes.

O vault é uma cópia, não um link: o conteúdo nunca volta para este repo. Nenhum dos dois usa git, sync nem plugins da comunidade.

## Workspace (repos + wiki local na mesma pasta)

Para trabalhar com o Claude Code em vários repos e no wiki ao mesmo tempo, sem misturar os dois:

```sh
~/dotfiles/workspace/new-workspace.sh --lite ~/work/projeto    # raiz + wiki/ (lite) + guides/
git clone <url> ~/work/projeto/<nome>                          # cada repo dentro da raiz
~/dotfiles/workspace/new-workspace.sh --check ~/work/projeto   # confere a estrutura
cd ~/work/projeto && claude                                    # sempre na raiz
```

- A raiz **não é git**: um `git add` no lugar errado falha em vez de subir nota do wiki para um repo. O wiki também não tem git.
- `CLAUDE.md` da raiz: o papel de cada pasta, um repo por tarefa (`git -C <repo> ...`), o wiki nunca vai para os repos, PR em draft, nada de dado de negócio.
- `.claude/settings.json` da raiz: deny do SDK do ServiceNow (install, deploy, exec, cicd, auth --print/--add/--delete), de force-push, push na main/master, `gh pr merge`, `git init` e de leitura de `~/.now-sdk/`.
- O Claude Code só lê o `.claude/settings.json` da pasta onde abre. Abrindo na raiz, o settings de cada repo **não vale**; o `--check` avisa quando um repo tem um, para você levar as regras dele para a raiz.
- `--update` troca o `CLAUDE.md` e o `settings.json` da raiz (o anterior vira `.bak`). O wiki atualiza à parte com `new-vault.sh --update`.

## Regra

Nada de segredo aqui: o repo é público. Token, chave e `.env` ficam fora.
