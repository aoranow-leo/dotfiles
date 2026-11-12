#!/bin/zsh
# Clona a documentação oficial do ServiceNow (github.com/ServiceNow/ServiceNowDocs) em <workspace>/refs/,
# só a release e as áreas pedidas, e monta o índice de busca (tools/docsearch.py).
#   ~/dotfiles/workspace/add-servicenow-docs.sh ~/work/projeto                       # australia, áreas padrão
#   ~/dotfiles/workspace/add-servicenow-docs.sh --release brazil ~/work/projeto
#   ~/dotfiles/workspace/add-servicenow-docs.sh --areas "servicenow-platform it-service-management" ~/work/projeto
#   ~/dotfiles/workspace/add-servicenow-docs.sh --areas all ~/work/projeto           # tudo (~51 mil páginas, ~300 MB)
#   ~/dotfiles/workspace/add-servicenow-docs.sh --update ~/work/projeto              # puxa a versão nova e reindexa
# Releases = branches do repo: australia, brazil, zurich, yokohama, xanadu...
set -euo pipefail
URL="https://github.com/ServiceNow/ServiceNowDocs.git"
RELEASE="australia"
AREAS="servicenow-platform platform-administration platform-user-interface application-development build-workflows platform-security customer-service-management integrate-applications api-reference"
UPDATE=""

usage() { echo "uso: add-servicenow-docs.sh [--release <r>] [--areas \"a b\" | --areas all] [--update] <workspace>"; exit 1; }
while [[ "${1:-}" == --* ]]; do
  case "$1" in
    --release) RELEASE="${2:?}"; shift ;;
    --areas) AREAS="${2:?}"; shift ;;
    --update) UPDATE=1 ;;
    *) usage ;;
  esac
  shift
done
[[ $# -eq 1 ]] || usage
WS="${1:A}"
DEST="$WS/refs/servicenow-docs"
[[ -f "$WS/tools/docsearch.py" ]] || { echo "Não achei $WS/tools/docsearch.py. Rode new-workspace.sh --update \"$WS\" antes."; exit 1; }

if [[ -n "$UPDATE" ]]; then
  [[ -d "$DEST/.git" ]] || { echo "Não há clone em $DEST"; exit 1; }
  RELEASE="$(git -C "$DEST" rev-parse --abbrev-ref HEAD)"
  git -C "$DEST" fetch -q --depth 1 origin "$RELEASE"
  git -C "$DEST" reset -q --hard FETCH_HEAD
else
  [[ -e "$DEST" ]] && { echo "Já existe: $DEST (para atualizar: --update)"; exit 1; }
  mkdir -p "$WS/refs"
  git clone -q --depth 1 --filter=blob:none --sparse --single-branch --branch "$RELEASE" "$URL" "$DEST"
  if [[ "$AREAS" == all ]]; then
    git -C "$DEST" sparse-checkout disable
  else
    paths=()
    for a in ${=AREAS}; do paths+=("markdown/$a"); done
    git -C "$DEST" sparse-checkout set "${paths[@]}"
  fi
fi

python3 "$WS/tools/docsearch.py" index servicenow-docs
echo "release: $RELEASE · $(find "$DEST/markdown" -name '*.md' | wc -l | tr -d ' ') páginas · $(du -sh "$DEST" | cut -f1)"
echo "Buscar: python3 tools/docsearch.py search servicenow-docs ui policy"
