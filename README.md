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

`obsidian/vault-template/` é o esqueleto de um vault no padrão LLM Wiki: `CLAUDE.md` (regras da LLM), templates, Bases, taxonomia e painel. Não tem conteúdo.

```sh
~/dotfiles/obsidian/new-vault.sh ~/Documents/Wiki            # cria (cópia, sem git, sem sync)
~/dotfiles/obsidian/new-vault.sh --update ~/Documents/Wiki   # só troca schema, guia, templates e Bases
```

O vault é uma cópia, não um link: o conteúdo nunca volta para este repo. Por padrão o template não usa git, sync nem plugins da comunidade (ver `CLAUDE.md` §0.1).

## Regra

Nada de segredo aqui: o repo é público. Token, chave e `.env` ficam fora.
