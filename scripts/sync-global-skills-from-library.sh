#!/usr/bin/env bash
# Sync global skills from jarvis-skills-library into .agents/skills/
# Usage:
#   JARVIS_SKILLS_LIBRARY=/var/www/html/proyectos/AIPP/jarvis-skills-library \
#     ./scripts/sync-global-skills-from-library.sh
#
# See: MAINTENANCE_SKILLS.md, docs/ZONIX_JARVIS_INTEGRATION.md

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
LIBRARY="${JARVIS_SKILLS_LIBRARY:-/var/www/html/proyectos/AIPP/jarvis-skills-library}"
DEST_BASE="$REPO_ROOT/.agents/skills"
MANIFEST="$DEST_BASE/.global-sync-manifest"

if [[ ! -d "$LIBRARY/skills" ]]; then
  echo "ERROR: library not found: $LIBRARY/skills" >&2
  exit 1
fi
if [[ ! -f "$MANIFEST" ]]; then
  echo "ERROR: manifest not found: $MANIFEST" >&2
  exit 1
fi

find_library_skill() {
  local name="$1"
  local path
  path="$(find "$LIBRARY/skills" -mindepth 2 -maxdepth 2 -type d -name "$name" 2>/dev/null | head -1)"
  if [[ -z "$path" || ! -f "$path/SKILL.md" ]]; then
    echo "ERROR: $name not found in library under skills/*/$name/" >&2
    return 1
  fi
  echo "$path/SKILL.md"
}

synced=0
while read -r line; do
  line="${line%%#*}"
  line="$(echo "$line" | xargs)"
  [[ -z "$line" ]] && continue
  read -r skill tier <<< "$line"
  if [[ "$tier" != "passthrough" && "$tier" != "overlay" ]]; then
    echo "ERROR: invalid tier '$tier' for $skill (use passthrough|overlay)" >&2
    exit 1
  fi
  src="$(find_library_skill "$skill")"
  dest_dir="$DEST_BASE/$skill"
  mkdir -p "$dest_dir"
  if [[ "$tier" == "passthrough" ]]; then
    cp "$src" "$dest_dir/SKILL.md"
  else
    overlay="$dest_dir/OVERLAY.md"
    if [[ ! -f "$overlay" ]]; then
      echo "ERROR: overlay tier requires $overlay" >&2
      exit 1
    fi
    {
      cat "$src"
      echo ""
      echo "---"
      echo ""
      cat "$overlay"
    } > "$dest_dir/SKILL.md"
  fi
  echo "OK: $skill ($tier)"
  synced=$((synced + 1))
done < "$MANIFEST"

echo "Done: synced $synced skills from $LIBRARY -> $DEST_BASE"
