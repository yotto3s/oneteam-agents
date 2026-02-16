#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------------------
# install.sh — Install oneteam-agents (and optionally superpowers) via file copy
# ---------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd -P)"

# Defaults (empty means "prompt the user")
TARGET=""
SUPERPOWERS=""   # "yes" | "no" | "" (prompt)
UNINSTALL=false

# ── Usage ──────────────────────────────────────────────────────────────────

usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Install oneteam-agents (and optionally superpowers) into a Claude Code
config directory via file copy.

Options:
  --target <path>       Target directory (default: ~/.claude, skips prompt)
  --with-superpowers    Include superpowers items (skips prompt)
  --no-superpowers      Skip superpowers items (skips prompt)
  --uninstall           Remove previously installed files
  -h, --help            Show this help message

Interactive mode:
  When --target is not provided, prompts for the install directory.
  When neither --with-superpowers nor --no-superpowers is provided,
  prompts whether to include superpowers.
EOF
  exit 0
}

# ── Argument parsing ───────────────────────────────────────────────────────

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target)
      TARGET="$2"
      shift 2
      ;;
    --with-superpowers)
      SUPERPOWERS="yes"
      shift
      ;;
    --no-superpowers)
      SUPERPOWERS="no"
      shift
      ;;
    --uninstall)
      UNINSTALL=true
      shift
      ;;
    -h|--help)
      usage
      ;;
    *)
      echo "Unknown option: $1" >&2
      echo "Run '$(basename "$0") --help' for usage." >&2
      exit 1
      ;;
  esac
done

# ── Interactive prompts (when flags not provided) ──────────────────────────

if [[ -z "$TARGET" ]]; then
  read -rp "Install target [~/.claude]: " TARGET
  TARGET="${TARGET:-$HOME/.claude}"
fi

# Expand ~ at the start of TARGET
TARGET="${TARGET/#\~/$HOME}"

if [[ "$UNINSTALL" == false && -z "$SUPERPOWERS" ]]; then
  read -rp "Install superpowers? (not needed if already installed as plugin) [y/N]: " sp_answer
  case "${sp_answer,,}" in
    y|yes) SUPERPOWERS="yes" ;;
    *)     SUPERPOWERS="no"  ;;
  esac
fi

# Resolve TARGET to an absolute path (create parent first so resolution works)
mkdir -p "$TARGET"
TARGET="$(cd "$TARGET" && pwd -P)"

# ── Self-install guard ─────────────────────────────────────────────────────

if [[ "$TARGET" == "$SCRIPT_DIR" ]]; then
  echo "Error: target directory is the repo itself ($SCRIPT_DIR)." >&2
  echo "Choose a different target (e.g. ~/.claude)." >&2
  exit 1
fi

# ── Helpers ────────────────────────────────────────────────────────────────

# Copy a single agent file.
#   $1 = absolute source path  (e.g. /repo/agents/foo.md)
#   $2 = target agents dir     (e.g. /home/user/.claude/agents)
#   $3 = source label           (e.g. "oneteam-agents")
#   $4 = optional override note (e.g. ", overrides superpowers")
# Returns 0 on success.
copy_agent() {
  local src="$1" target_dir="$2" label="$3" note="${4:-}"
  local name
  name="$(basename "$src")"
  local dest="$target_dir/$name"

  cp "$src" "$dest"
  echo "  + $name ($label$note)"
  return 0
}

# Copy a single skill directory.
#   $1 = absolute source path  (e.g. /repo/skills/foo)
#   $2 = target skills dir     (e.g. /home/user/.claude/skills)
#   $3 = source label
#   $4 = optional override note
copy_skill() {
  local src="$1" target_dir="$2" label="$3" note="${4:-}"
  local name
  name="$(basename "$src")"
  local dest="$target_dir/$name"

  rm -rf "$dest"
  cp -r "$src" "$dest"
  echo "  + $name ($label$note)"
  return 0
}

# ── Install ────────────────────────────────────────────────────────────────

do_install() {
  local agent_count=0 skill_count=0 override_count=0
  local -a manifest=()

  mkdir -p "$TARGET/agents" "$TARGET/skills"

  # Build override sets from oneteam-agents ---------------------------------
  declare -A override_agents=()
  declare -A override_skills=()

  for f in "$SCRIPT_DIR"/agents/*.md; do
    [[ -e "$f" ]] || continue
    override_agents["$(basename "$f")"]=1
  done

  for d in "$SCRIPT_DIR"/skills/*/; do
    [[ -d "$d" ]] || continue
    override_skills["$(basename "$d")"]=1
  done

  # 1. Copy oneteam-agents agents ----------------------------------------
  echo "Installing agents..."
  for f in "$SCRIPT_DIR"/agents/*.md; do
    [[ -e "$f" ]] || continue
    local name
    name="$(basename "$f")"
    local note=""
    # Check if superpowers has this agent (for the annotation)
    if [[ "$SUPERPOWERS" == "yes" && -e "$SCRIPT_DIR/external/superpowers/agents/$name" ]]; then
      note=", overrides superpowers"
    fi
    if copy_agent "$f" "$TARGET/agents" "oneteam-agents" "$note"; then
      (( agent_count++ )) || true
      manifest+=("agents/$name")
    fi
  done

  # 2. Copy oneteam-agents skills ----------------------------------------
  echo "Installing skills..."
  for d in "$SCRIPT_DIR"/skills/*/; do
    [[ -d "$d" ]] || continue
    local name
    name="$(basename "$d")"
    local note=""
    if [[ "$SUPERPOWERS" == "yes" && -d "$SCRIPT_DIR/external/superpowers/skills/$name" ]]; then
      note=", overrides superpowers"
    fi
    if copy_skill "$d" "$TARGET/skills" "oneteam-agents" "$note"; then
      (( skill_count++ )) || true
      manifest+=("skills/$name")
    fi
  done

  # 3. Superpowers (if enabled) ---------------------------------------------
  if [[ "$SUPERPOWERS" == "yes" ]]; then
    # Ensure the submodule is initialized
    git -C "$SCRIPT_DIR" submodule update --init external/superpowers

    local sp_agents_dir="$SCRIPT_DIR/external/superpowers/agents"
    local sp_skills_dir="$SCRIPT_DIR/external/superpowers/skills"

    # Superpowers agents (skip overrides)
    if [[ -d "$sp_agents_dir" ]]; then
      for f in "$sp_agents_dir"/*.md; do
        [[ -e "$f" ]] || continue
        local name
        name="$(basename "$f")"
        if [[ -n "${override_agents[$name]:-}" ]]; then
          (( override_count++ )) || true
          continue
        fi
        if copy_agent "$f" "$TARGET/agents" "superpowers"; then
          (( agent_count++ )) || true
          manifest+=("agents/$name")
        fi
      done
    fi

    # Superpowers skills (skip overrides)
    if [[ -d "$sp_skills_dir" ]]; then
      for d in "$sp_skills_dir"/*/; do
        [[ -d "$d" ]] || continue
        local name
        name="$(basename "$d")"
        if [[ -n "${override_skills[$name]:-}" ]]; then
          (( override_count++ )) || true
          continue
        fi
        if copy_skill "$d" "$TARGET/skills" "superpowers"; then
          (( skill_count++ )) || true
          manifest+=("skills/$name")
        fi
      done
    fi
  fi

  # 4. Patch implementer-prompt.md for agent role dispatch ----------------------
  local impl_prompt="$TARGET/skills/subagent-driven-development/implementer-prompt.md"
  if [[ -f "$impl_prompt" ]]; then
    sed -i "s/Task tool (general-purpose)/Task tool (junior-engineer or senior-engineer — use the task's **Agent role** from the plan)/" "$impl_prompt"
    echo "Patched implementer-prompt.md for agent role dispatch"
  fi

  # Write manifest for uninstall
  printf '%s\n' "${manifest[@]}" > "$TARGET/.oneteam-manifest"

  # Summary ------------------------------------------------------------------
  local summary="Installed: $agent_count agents, $skill_count skills"
  if [[ "$override_count" -gt 0 ]]; then
    summary+=" (skipped $override_count superpowers overrides)"
  fi
  echo "$summary"
}

# ── Uninstall ──────────────────────────────────────────────────────────────

do_uninstall() {
  local removed=0
  local manifest_file="$TARGET/.oneteam-manifest"

  if [[ -f "$manifest_file" ]]; then
    echo "Uninstalling using manifest..."
    while IFS= read -r entry; do
      [[ -z "$entry" ]] && continue
      local target_path="$TARGET/$entry"
      if [[ -d "$target_path" ]]; then
        echo "  - $entry"
        rm -rf "$target_path"
        (( removed++ )) || true
      elif [[ -f "$target_path" ]]; then
        echo "  - $entry"
        rm "$target_path"
        (( removed++ )) || true
      fi
    done < "$manifest_file"
    rm "$manifest_file"
  else
    # Fallback: legacy symlink-based detection
    echo "No manifest found. Falling back to symlink detection..."
    for subdir in agents skills; do
      local dir="$TARGET/$subdir"
      [[ -d "$dir" ]] || continue
      for entry in "$dir"/*; do
        [[ -L "$entry" ]] || continue
        local link_target
        link_target="$(realpath "$entry" 2>/dev/null || true)"
        if [[ "$link_target" == "$SCRIPT_DIR"/* ]]; then
          echo "  - $(basename "$entry") ($subdir)"
          rm "$entry"
          (( removed++ )) || true
        fi
      done
    done
  fi

  echo "Removed: $removed items"
}

# ── Main dispatch ──────────────────────────────────────────────────────────

if [[ "$UNINSTALL" == true ]]; then
  do_uninstall
else
  do_install
fi
