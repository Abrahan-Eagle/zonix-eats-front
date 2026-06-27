#!/usr/bin/env bash
# Verify .agents/skills match jarvis-skills-library manifest (hashes + overlays).
# Usage:
#   JARVIS_SKILLS_LIBRARY=/var/www/html/proyectos/AIPP/jarvis-skills-library \
#     ./scripts/check-global-skills-sync.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
LIBRARY="${JARVIS_SKILLS_LIBRARY:-/var/www/html/proyectos/AIPP/jarvis-skills-library}"
DEST_BASE="$REPO_ROOT/.agents/skills"
MANIFEST="$DEST_BASE/.global-sync-manifest"
LOCK="$LIBRARY/skills-lock.json"

errors=0

if [[ ! -f "$MANIFEST" ]]; then
  echo "FAIL: missing manifest $MANIFEST" >&2
  exit 1
fi
if [[ ! -f "$LOCK" ]]; then
  echo "FAIL: missing library lock $LOCK" >&2
  exit 1
fi

find_library_skill() {
  local name="$1"
  find "$LIBRARY/skills" -mindepth 2 -maxdepth 2 -type d -name "$name" 2>/dev/null | head -1
}

while read -r line; do
  line="${line%%#*}"
  line="$(echo "$line" | xargs)"
  [[ -z "$line" ]] && continue
  read -r skill tier <<< "$line"

  if ! grep -q "\"$skill\"" "$LOCK"; then
    echo "FAIL: $skill not in library skills-lock.json" >&2
    errors=$((errors + 1))
    continue
  fi

  lib_dir="$(find_library_skill "$skill")"
  if [[ -z "$lib_dir" || ! -f "$lib_dir/SKILL.md" ]]; then
    echo "FAIL: $skill missing in library" >&2
    errors=$((errors + 1))
    continue
  fi

  dest="$DEST_BASE/$skill/SKILL.md"
  if [[ ! -f "$dest" ]]; then
    echo "FAIL: $dest missing (run sync-global-skills-from-library.sh)" >&2
    errors=$((errors + 1))
    continue
  fi

  if [[ "$tier" == "overlay" ]]; then
    overlay="$DEST_BASE/$skill/OVERLAY.md"
    if [[ ! -f "$overlay" ]]; then
      echo "FAIL: missing $overlay" >&2
      errors=$((errors + 1))
      continue
    fi
    expected="$(mktemp)"
    {
      cat "$lib_dir/SKILL.md"
      echo ""
      echo "---"
      echo ""
      cat "$overlay"
    } > "$expected"
    if ! cmp -s "$expected" "$dest"; then
      echo "FAIL: $skill SKILL.md drift (run sync-global-skills-from-library.sh)" >&2
      errors=$((errors + 1))
    fi
    rm -f "$expected"
  else
    if ! cmp -s "$lib_dir/SKILL.md" "$dest"; then
      echo "FAIL: $skill passthrough drift (run sync-global-skills-from-library.sh)" >&2
      errors=$((errors + 1))
    fi
  fi
done < "$MANIFEST"

if [[ "$errors" -gt 0 ]]; then
  echo "check-global-skills-sync: $errors error(s)" >&2
  exit 1
fi

echo "OK: global skills sync check passed ($MANIFEST)"
