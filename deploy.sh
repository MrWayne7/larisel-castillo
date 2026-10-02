#!/usr/bin/env bash
# Publica una pagina estatica: GitHub (git/gh) + Cloudflare Pages (Wrangler).
# Uso: bash deploy.sh <nombre-proyecto> [carpeta]
#   <nombre-proyecto>  ->  sera tu subdominio: https://<nombre-proyecto>.pages.dev
#   [carpeta]          ->  carpeta con el index.html (por defecto: la actual ".")
set -euo pipefail

PROJECT="${1:?Uso: bash deploy.sh <nombre-proyecto> [carpeta]}"
DIR="${2:-.}"
cd "$DIR"

# 1) La pagina debe tener index.html en la raiz
if [ ! -f index.html ]; then
  echo "❌ No encuentro index.html en '$DIR'. Renombralo/muevelo y reintenta."
  exit 1
fi

# 2) Herramientas
command -v gh  >/dev/null 2>&1 || { echo "❌ Falta gh (brew install gh)"; exit 1; }
command -v npx >/dev/null 2>&1 || { echo "❌ Falta node/npx (brew install node)"; exit 1; }

# 3) GitHub: init + commit + repo/push
if [ ! -d .git ]; then
  git init -q
fi
git add -A
git commit -q -m "deploy: $(date '+%Y-%m-%d %H:%M:%S')" || echo "ℹ️  Nada nuevo que commitear."

if git remote get-url origin >/dev/null 2>&1; then
  git push -q -u origin HEAD
else
  echo "→ Creando repo '$PROJECT' en GitHub y haciendo push…"
  gh repo create "$PROJECT" --public --source=. --remote=origin --push
fi

# 4) Cloudflare Pages (gratis, Direct Upload, sin dashboard)
echo "→ Desplegando en Cloudflare Pages como '$PROJECT'…"
npx wrangler@latest pages deploy . --project-name="$PROJECT" --commit-dirty=true

echo ""
echo "✅ Listo. Produccion: https://${PROJECT}.pages.dev"
