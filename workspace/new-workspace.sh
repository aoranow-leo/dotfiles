#!/bin/zsh
# Cria uma pasta de trabalho com repos de cliente + wiki local lado a lado (a raiz não é git).
#   ~/dotfiles/workspace/new-workspace.sh [--lite] ~/work/cliente   # cria raiz + wiki/ + guides/
#   ~/dotfiles/workspace/new-workspace.sh --update ~/work/cliente   # troca CLAUDE.md, .claude/settings.json e tools/docsearch.py
#   ~/dotfiles/workspace/new-workspace.sh --check  ~/work/cliente   # confere se a estrutura continua segura
# Os repos você clona depois, dentro da raiz:  git clone <url> ~/work/cliente/<nome>
set -euo pipefail
HERE="${0:A:h}"
TPL="$HERE/template"
STAMP="$(date +%Y%m%d%H%M%S)"

usage() { echo "uso: new-workspace.sh [--lite | --update | --check] <pasta>"; exit 1; }
MODE="create"
LITE=""
while [[ "${1:-}" == --* ]]; do
  case "$1" in
    --lite) LITE="--lite" ;;
    --update) MODE="update" ;;
    --check) MODE="check" ;;
    *) usage ;;
  esac
  shift
done
[[ $# -eq 1 ]] || usage
DEST="${1:A}"

is_git() { git -C "$1" rev-parse --is-inside-work-tree >/dev/null 2>&1; }

check() {
  local errs=0 warns=0
  err()  { echo "ERRO   $*"; errs=$((errs+1)); }
  warn() { echo "AVISO  $*"; warns=$((warns+1)); }
  ok()   { echo "ok     $*"; }

  [[ -d "$DEST" ]] || { echo "ERRO   pasta não existe: $DEST"; return 1; }
  if is_git "$DEST"; then err "a raiz está dentro de um repo git ($(git -C "$DEST" rev-parse --show-toplevel)). Tire ou apague esse .git."
  else ok "raiz fora do git"; fi

  [[ -f "$DEST/CLAUDE.md" ]] && ok "CLAUDE.md da raiz" || err "falta CLAUDE.md na raiz (rode --update)"
  if [[ -f "$DEST/.claude/settings.json" ]]; then
    if python3 -c "import json,sys; json.load(open(sys.argv[1]))" "$DEST/.claude/settings.json" 2>/dev/null; then
      ok ".claude/settings.json da raiz"
    else err ".claude/settings.json da raiz não é JSON válido"; fi
  else err "falta .claude/settings.json na raiz (rode --update)"; fi

  if [[ -d "$DEST/wiki" ]]; then
    [[ -e "$DEST/wiki/.git" ]] && err "wiki/ tem .git. O wiki é só local: apague wiki/.git" || ok "wiki/ sem git"
    [[ -f "$DEST/wiki/CLAUDE.md" ]] || warn "wiki/ sem CLAUDE.md"
  else warn "não há wiki/"; fi

  local repos=0 d name
  for d in "$DEST"/*(N/); do
    name="${d:t}"
    [[ "$name" == wiki || "$name" == guides || "$name" == tools ]] && continue
    if [[ "$name" == refs ]]; then
      local r
      for r in "$d"/*(N/); do
        if [[ -e "$r/.git" ]]; then
          if [[ -n "$(git -C "$r" status --porcelain --untracked-files=no 2>/dev/null)" ]]; then
            warn "refs/${r:t} tem arquivos alterados. refs/ é só leitura: git -C \"$r\" reset --hard"
          else ok "ref: ${r:t}"; fi
          [[ -f "$DEST/refs/.search/${r:t}.db" ]] || warn "refs/${r:t} sem índice de busca: python3 tools/docsearch.py index ${r:t}"
        fi
      done
      continue
    fi
    if [[ -e "$d/.git" ]]; then
      repos=$((repos+1)); ok "repo: $name"
      [[ -f "$d/.claude/settings.json" ]] && warn "$name/.claude/settings.json NÃO vale quando o Claude abre na raiz. Leve as regras dele para o settings.json da raiz."
      local sfiles=("$d"/.claude/settings*.json(N))
      [[ -d "$d/.claude/hooks" ]] || { (( ${#sfiles} )) && grep -q '"hooks"' "${sfiles[@]}"; } && warn "$name tem hooks do Claude Code que não rodam a partir da raiz."
      [[ -e "$d/wiki" ]] && warn "$name contém uma pasta wiki/; confira que não é o wiki local"
    else
      warn "$name não é repo nem wiki/guides. Se for conteúdo do wiki, mova para wiki/."
    fi
  done
  (( repos > 0 )) || warn "nenhum repo clonado ainda"

  echo "--- $errs erro(s), $warns aviso(s)"
  (( errs == 0 ))
}

case "$MODE" in
  check)
    check
    ;;
  update)
    [[ -f "$DEST/CLAUDE.md" || -d "$DEST/.claude" ]] || { echo "Não parece um workspace: $DEST"; exit 1; }
    mkdir -p "$DEST/.claude"
    mkdir -p "$DEST/tools"
    for p in CLAUDE.md .claude/settings.json tools/docsearch.py; do
      [[ -e "$DEST/$p" ]] && mv "$DEST/$p" "$DEST/$p.bak.$STAMP"
      cp "$TPL/$p" "$DEST/$p"
      echo "atualizado: $p"
    done
    echo "O wiki se atualiza à parte: ~/dotfiles/obsidian/new-vault.sh --update \"$DEST/wiki\""
    ;;
  create)
    if [[ -e "$DEST" && -n "$(ls -A "$DEST" 2>/dev/null)" ]]; then
      echo "A pasta já existe e não está vazia: $DEST"
      echo "Para trocar só o CLAUDE.md e o settings.json: new-workspace.sh --update \"$DEST\""
      exit 1
    fi
    mkdir -p "$DEST"
    if is_git "$DEST"; then
      echo "Não crio dentro de um repo git ($(git -C "$DEST" rev-parse --show-toplevel)). Escolha outra pasta."
      rmdir "$DEST" 2>/dev/null || true
      exit 1
    fi
    cp -R "$TPL/." "$DEST/"
    mkdir -p "$DEST/guides" "$DEST/refs"
    "$HERE/../obsidian/new-vault.sh" ${LITE:+$LITE} "$DEST/wiki"
    echo
    echo "Workspace criado em $DEST"
    echo "Próximos passos:"
    echo "  1. clonar os repos dentro dela:   git clone <url> \"$DEST/<nome>\""
    echo "     (opcional) doc do ServiceNow:  $HERE/add-servicenow-docs.sh \"$DEST\""
    echo "  2. conferir:                       $0 --check \"$DEST\""
    echo "  3. abrir o Claude Code SEMPRE na raiz:  cd \"$DEST\" && claude"
    ;;
esac
