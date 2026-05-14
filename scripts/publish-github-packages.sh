#!/usr/bin/env bash

set -euo pipefail

OWNER="${GITHUB_PACKAGES_OWNER:-${GITHUB_REPOSITORY_OWNER:-aleksUIX}}"
TOKEN="${GITHUB_PACKAGES_TOKEN:-${GITHUB_TOKEN:-}}"

if [[ -z "$TOKEN" ]]; then
  echo "GITHUB_PACKAGES_TOKEN or GITHUB_TOKEN is required" >&2
  echo "Use GITHUB_TOKEN in GitHub Actions, or a classic GitHub personal access token with write:packages locally" >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "$REPO_ROOT"

VERSION="$(ruby -Ilib -e 'require "vastlint/version"; print Vastlint::VERSION')"
GEM_FILE="vastlint-${VERSION}.gem"

if [[ ! -f "$GEM_FILE" ]]; then
  gem build vastlint.gemspec
fi

TMP_HOME="$(mktemp -d)"
trap 'rm -rf "$TMP_HOME"' EXIT

mkdir -p "$TMP_HOME/.gem"
chmod 700 "$TMP_HOME/.gem"

cat > "$TMP_HOME/.gem/credentials" <<EOF
---
:github: Bearer ${TOKEN}
EOF

chmod 600 "$TMP_HOME/.gem/credentials"

HOME="$TMP_HOME" gem push \
  --key github \
  --host "https://rubygems.pkg.github.com/${OWNER}" \
  "$GEM_FILE"
