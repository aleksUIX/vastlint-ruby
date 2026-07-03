#!/usr/bin/env bash

set -euo pipefail

API_KEY="${RUBYGEMS_API_KEY:-}"

if [[ -z "$API_KEY" ]]; then
  echo "RUBYGEMS_API_KEY is required (an API key from https://rubygems.org/profile/api_keys with Push rights)" >&2
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
:rubygems_api_key: ${API_KEY}
EOF

chmod 600 "$TMP_HOME/.gem/credentials"

HOME="$TMP_HOME" gem push "$GEM_FILE"
