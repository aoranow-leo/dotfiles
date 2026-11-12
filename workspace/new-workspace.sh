#!/bin/zsh
# Pasta de trabalho com repos de cliente, wiki local, guias e docs de referência lado a lado (a raiz não é git).
#   ~/dotfiles/workspace/new-workspace.sh [--lite] ~/work/cliente   # cria raiz + wiki/ + guides/ + refs/ + tools/
#   ~/dotfiles/workspace/new-workspace.sh --link   ~/work/cliente   # depois de clonar: settings.local.json em cada repo
#   ~/dotfiles/workspace/new-workspace.sh --user-deny                # seus bloqueios pessoais no ~/.claude/settings.json
#   ~/dotfiles/workspace/new-workspace.sh --update ~/work/cliente   # troca CLAUDE.md da raiz e tools/docsearch.py
#   ~/dotfiles/workspace/new-workspace.sh --check  ~/work/cliente   # confere se está tudo no lugar
# O Claude Code abre DENTRO do repo (cd <repo> && claude): valem as regras do repo + as suas.
set -euo pipefail
HERE="${0:A:h}"
TPL="$HERE/template"
MERGE=(python3 "$HERE/settings_merge.py")
USER_SETTINGS="$HOME/.claude/settings.json"
STAMP="$(date +%Y%m%d%H%M%S)"

usage() { echo "uso: new-workspace.sh [--lite | --link | --update | --check] <pasta>  |  new-workspace.sh --user-deny"; exit 1; }
MODE="create"
LITE=""
while [[ "${1:-}" == --* ]]; do
  case "$1" in
    --lite) LITE="--lite" ;;
    --link) MODE="link" ;;
    --update) MODE="update" ;;
    --check) MODE="check" ;;
    --user-deny) MODE="user" ;;
    *) usage ;;
  esac
  shift
done
if [[ "$MODE" == user ]]; then
  [[ $# -eq 0 ]] || usage
  "${MERGE[@]}" user "$HERE/user-deny.json" "$USER_SETTINGS"
  exit 0
fi
[[ $# -eq 1 ]] || usage
DEST="${1:A}"

is_git() { git -C "$1" rev-parse --is-inside-work-tree >/dev/null 2>&1; }
repos() {
  local d
  for d in "$DEST"/*(N/); do
    [[ "${d:t}" == (wiki|guides|refs|tools) ]] && continue
    [[ -e "$d/.git" ]] && print -r -- "$d"
  done
  return 0
}

check() {
  local errs=0 warns=0
  err()  { echo "ERRO   $*"; errs=$((errs+1)); }
  warn() { echo "AVISO  $*"; warns=$((warns+1)); }
  ok()   { echo "ok     $*"; }

  [[ -d "$DEST" ]] || { echo "ERRO   pasta não existe: $DEST"; return 1; }
  if is_git "$DEST"; then err "a raiz está dentro de um repo git ($(git -C "$DEST" rev-parse --show-toplevel)). Tire ou apague esse .git."
  else ok "raiz fora do git"; fi
  [[ -f "$DEST/CLAUDE.md" ]] && ok "CLAUDE.md da raiz" || err "falta CLAUDE.md na raiz (rode --update)"
  [[ -f "$DEST/.claude/settings.json" ]] && warn ".claude/settings.json na raiz é do layout antigo; ele só vale abrindo na raiz. Pode apagar."

  if [[ -d "$DEST/wiki" ]]; then
    [[ -e "$DEST/wiki/.git" ]] && err "wiki/ tem .git. O wiki é só local: apague wiki/.git" || ok "wiki/ sem git"
    [[ -f "$DEST/wiki/CLAUDE.md" ]] || warn "wiki/ sem CLAUDE.md"
    [[ -f "$DEST/wiki/scripts/wiki.py" ]] || warn "wiki/ sem scripts/wiki.py (os guias rodam ele no fim)"
  else warn "não há wiki/"; fi

  "${MERGE[@]}" check-user "$HERE/user-deny.json" "$USER_SETTINGS" | sed 's/^WARN  /AVISO  /;s/^OK    /ok     /' || warns=$((warns+1))

  local r n=0
  for r in "$DEST"/refs/*(N/); do
    [[ -e "$r/.git" ]] || continue
    if [[ -n "$(git -C "$r" status --porcelain --untracked-files=no 2>/dev/null)" ]]; then
      warn "refs/${r:t} tem arquivos alterados. refs/ é só leitura: git -C \"$r\" reset --hard"
    else ok "ref: ${r:t}"; fi
    [[ -f "$DEST/refs/.search/${r:t}.db" ]] || warn "refs/${r:t} sem índice de busca: python3 tools/docsearch.py index ${r:t}"
  done

  local -a rl=(${(f)"$(repos)"})
  for r in "${rl[@]}"; do
    n=$((n+1)); ok "repo: ${r:t}"
    "${MERGE[@]}" check-repo "$DEST" "$r" | sed 's/^WARN  /AVISO  /;s/^OK    /ok     /' || warns=$((warns+1))
    if [[ -f "$r/.claude/settings.local.json" ]] && ! git -C "$r" check-ignore -q .claude/settings.local.json; then
      err "${r:t}/.claude/settings.local.json NÃO está no .gitignore do repo; ele tem caminhos desta máquina. Ponha no .git/info/exclude: echo .claude/settings.local.json >> \"$r/.git/info/exclude\""
    fi
    [[ -e "$r/wiki" ]] && warn "${r:t} contém uma pasta wiki/; confira que não é o wiki local"
  done
  for r in "$DEST"/*(N/); do
    [[ "${r:t}" == (wiki|guides|refs|tools) || -e "$r/.git" ]] || warn "${r:t} não é repo nem wiki/guides/refs/tools."
  done
  (( n > 0 )) || warn "nenhum repo clonado ainda"

  echo "--- $errs erro(s), $warns aviso(s)"
  (( errs == 0 ))
}

case "$MODE" in
  check)
    check
    ;;
  link)
    [[ -f "$DEST/CLAUDE.md" ]] || { echo "Não parece um workspace: $DEST"; exit 1; }
    found=0
    rl=(${(f)"$(repos)"})
    for r in "${rl[@]}"; do
      found=1
      "${MERGE[@]}" repo "$DEST" "$r"
      git -C "$r" check-ignore -q .claude/settings.local.json || {
        echo ".claude/settings.local.json" >> "$r/.git/info/exclude"
        echo "       ${r:t}: settings.local.json posto no .git/info/exclude (fica fora dos commits)"
      }
    done
    (( found )) || echo "Nenhum repo em $DEST. Clone primeiro: git clone <url> \"$DEST/<nome>\""
    ;;
  update)
    [[ -f "$DEST/CLAUDE.md" ]] || { echo "Não parece um workspace: $DEST"; exit 1; }
    mkdir -p "$DEST/tools"
    for p in CLAUDE.md tools/docsearch.py; do
      [[ -e "$DEST/$p" ]] && mv "$DEST/$p" "$DEST/$p.bak.$STAMP"
      cp "$TPL/$p" "$DEST/$p"
      echo "atualizado: $p"
    done
    echo "O wiki se atualiza à parte: ~/dotfiles/obsidian/new-vault.sh --update \"$DEST/wiki\""
    ;;
  create)
    if [[ -e "$DEST" && -n "$(ls -A "$DEST" 2>/dev/null)" ]]; then
      echo "A pasta já existe e não está vazia: $DEST (para trocar o CLAUDE.md: --update)"
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
    echo "  1. clonar os repos:             git clone <url> \"$DEST/<nome>\""
    echo "  2. ligar os repos ao workspace: $0 --link \"$DEST\""
    echo "  3. seus bloqueios (uma vez):    $0 --user-deny"
    echo "     (opcional) doc do ServiceNow: $HERE/add-servicenow-docs.sh \"$DEST\""
    echo "  4. conferir:                    $0 --check \"$DEST\""
    echo "  5. trabalhar:                   cd \"$DEST/<repo>\" && claude"
    ;;
esac
