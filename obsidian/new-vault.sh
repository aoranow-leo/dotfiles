#!/bin/zsh
# Cria um vault do Obsidian a partir do template (cópia, sem git, sem sync).
#   ~/dotfiles/obsidian/new-vault.sh ~/Documents/Wiki
#   ~/dotfiles/obsidian/new-vault.sh --update ~/Documents/Wiki   # só atualiza schema/templates/Bases
set -euo pipefail
TPL="${0:A:h}/vault-template"
STAMP="$(date +%Y%m%d%H%M%S)"

usage() { echo "uso: new-vault.sh [--update] <pasta-do-vault>"; exit 1; }
UPDATE=""
[[ "${1:-}" == "--update" ]] && { UPDATE=1; shift; }
[[ $# -eq 1 ]] || usage
DEST="${1:A}"

if [[ -n "$UPDATE" ]]; then
  [[ -f "$DEST/CLAUDE.md" ]] || { echo "Não parece um vault: $DEST"; exit 1; }
  # Atualiza só o que é "sistema": schema, guia, templates e Bases. Conteúdo e taxonomia ficam.
  for p in "CLAUDE.md" "Guia de Uso.md" "Templates" "Bases"; do
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
cp -R "$TPL/." "$DEST/"
mkdir -p "$DEST"/Projetos \
         "$DEST"/raw/{inbox,artigos,reunioes,threads,pdfs,assets} \
         "$DEST"/wiki/{fontes,entidades,conceitos,sinteses}
sed -i '' "s/{{DATE}}/$(date +%Y-%m-%d)/" "$DEST/log.md"

if git -C "$DEST" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Atenção: $DEST está dentro de um repositório git. O vault deveria ficar fora de git."
fi

echo "Vault criado em $DEST (sem git, sem sync)."
echo "Abra no Obsidian: Open folder as vault -> $DEST"
