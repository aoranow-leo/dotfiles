#!/bin/zsh
# Instala/atualiza os dotfiles nesta máquina. Pode rodar de novo quando quiser.
#   SKIP_BREW=1 ./install.sh   -> só faz os links e o git (sem Homebrew)
set -euo pipefail
DIR="${0:A:h}"
STAMP="$(date +%Y%m%d%H%M%S)"

say() { print -P "%F{cyan}==>%f $*"; }

# 1. Homebrew + pacotes do Brewfile
if [[ -z "${SKIP_BREW:-}" ]]; then
  if ! command -v brew >/dev/null 2>&1; then
    for b in /opt/homebrew/bin/brew /usr/local/bin/brew /home/linuxbrew/.linuxbrew/bin/brew; do
      [[ -x "$b" ]] && { eval "$("$b" shellenv)"; break; }
    done
  fi
  if ! command -v brew >/dev/null 2>&1; then
    say "Instalando Homebrew"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    for b in /opt/homebrew/bin/brew /usr/local/bin/brew /home/linuxbrew/.linuxbrew/bin/brew; do
      [[ -x "$b" ]] && { eval "$("$b" shellenv)"; break; }
    done
  fi
  brew analytics off
  say "brew bundle"
  brew bundle --file="$DIR/Brewfile"
  # evita o aviso "insecure directories" do compinit
  chmod go-w "$(brew --prefix)/share" "$(brew --prefix)/share/zsh" 2>/dev/null || true
fi

# 2. Links (o que já existir vira .bak.<data>)
link() {
  local src="$DIR/$1" dst="$2"
  mkdir -p "${dst:h}"
  if [[ -L "$dst" && "$(readlink "$dst")" == "$src" ]]; then
    return
  fi
  if [[ -e "$dst" || -L "$dst" ]]; then
    mv "$dst" "$dst.bak.$STAMP"
    say "backup: $dst -> $dst.bak.$STAMP"
  fi
  ln -s "$src" "$dst"
  say "link: $dst -> $src"
}
link zsh/zshrc          "$HOME/.zshrc"
link atuin/config.toml  "$HOME/.config/atuin/config.toml"

# 3. git: inclui a config compartilhada sem mexer em user.name/email
if ! git config --global --get-all include.path 2>/dev/null | grep -qxF "$DIR/git/gitconfig"; then
  git config --global --add include.path "$DIR/git/gitconfig"
  say "git: include.path -> $DIR/git/gitconfig"
fi

# 4. atuin: importa o histórico do zsh só na primeira vez
if command -v atuin >/dev/null 2>&1 && [[ ! -f "$HOME/.local/share/atuin/history.db" ]]; then
  atuin import zsh || true
fi

echo
say "Pronto. Abra um terminal novo."
git config --global user.email >/dev/null 2>&1 || \
  echo "   Falta: git config --global user.name \"...\" && git config --global user.email \"...\""
echo "   Coisas só desta máquina: ~/.zshrc.local"
echo "   Fonte do terminal: MesloLGS Nerd Font"
