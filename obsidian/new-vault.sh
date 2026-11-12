#!/bin/zsh
# Cria um vault do Obsidian a partir de um template (cópia, sem git, sem sync).
#   ~/dotfiles/obsidian/new-vault.sh ~/Documents/Wiki            # completo: projetos, tarefas, specs, Bases
#   ~/dotfiles/obsidian/new-vault.sh --lite ~/Documents/Wiki     # simples: 3 tipos de página + scripts/wiki.py
#   ~/dotfiles/obsidian/new-vault.sh --update ~/Documents/Wiki   # só atualiza os arquivos de sistema
set -euo pipefail
HERE="${0:A:h}"
STAMP="$(date +%Y%m%d%H%M%S)"

usage() { echo "uso: new-vault.sh [--lite] [--update] <pasta-do-vault>"; exit 1; }
UPDATE=""
LITE=""
while [[ "${1:-}" == --* ]]; do
  case "$1" in
    --update) UPDATE=1 ;;
    --lite) LITE=1 ;;
    *) usage ;;
  esac
  shift
done
[[ $# -eq 1 ]] || usage
DEST="${1:A}"

if [[ -n "$UPDATE" ]]; then
  [[ -f "$DEST/CLAUDE.md" ]] || { echo "Não parece um vault: $DEST"; exit 1; }
  # O vault lite é reconhecido pelo script dele; não precisa repetir --lite.
  [[ -f "$DEST/scripts/wiki.py" ]] && LITE=1
  # Atualiza só o que é "sistema". Conteúdo (e a taxonomia, no completo) fica.
  if [[ -n "$LITE" ]]; then
    TPL="$HERE/vault-template-lite"
    SYSTEM=("CLAUDE.md" "Guia de Uso.md" "scripts")
  else
    TPL="$HERE/vault-template"
    SYSTEM=("CLAUDE.md" "Guia de Uso.md" "Templates" "Bases")
  fi
  for p in "${SYSTEM[@]}"; do
    if [[ -e "$DEST/$p" ]]; then
      mv "$DEST/$p" "$DEST/$p.bak.$STAMP"
    fi
    cp -R "$TPL/$p" "$DEST/$p"
    echo "atualizado: $p (anterior em $p.bak.$STAMP)"
  done
  exit 0
fi

if [[ -e "$DEST" && -n "$(ls -A "$DEST" 2>/dev/null)" ]]; then
  echo "A pasta já existe e não está vazia: $DEST"
  echo "Para atualizar o schema de um vault existente: new-vault.sh --update \"$DEST\""
  exit 1
fi

mkdir -p "$DEST"
if [[ -n "$LITE" ]]; then
  cp -R "$HERE/vault-template-lite/." "$DEST/"
  mkdir -p "$DEST"/{raw,fontes,wiki,notas}
else
  cp -R "$HERE/vault-template/." "$DEST/"
  mkdir -p "$DEST"/Projetos \
           "$DEST"/raw/{inbox,artigos,reunioes,threads,pdfs,assets} \
           "$DEST"/wiki/{fontes,entidades,conceitos,sinteses}
fi
sed -i '' "s/{{DATE}}/$(date +%Y-%m-%d)/" "$DEST/log.md"

if git -C "$DEST" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Atenção: $DEST está dentro de um repositório git. O vault deveria ficar fora de git."
fi

echo "Vault criado em $DEST (sem git, sem sync)."
echo "Abra no Obsidian: Open folder as vault -> $DEST"
