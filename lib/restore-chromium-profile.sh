#!/usr/bin/env bash

# ════════════════════════════════════════════════════════════
# Generic Chromium-based Browser Profile Restoration
# ════════════════════════════════════════════════════════════
# Works with: Chromium, Chrome, Brave, Edge, Vivaldi, etc.
#
# Usage:
#   restore_chromium_profile <browser_config_dir> <browser_command>
#
# Example:
#   restore_chromium_profile ~/.config/chromium chromium-browser
#   restore_chromium_profile ~/.config/google-chrome google-chrome-stable
#   restore_chromium_profile ~/.config/BraveSoftware/Brave-Browser brave-browser
# ════════════════════════════════════════════════════════════

restore_chromium_profile() {
  local BROWSER_CONFIG_DIR="$1"
  local BROWSER_COMMAND="$2"
  local PROFILE_DIR="${BROWSER_CONFIG_DIR}/Default"
  local REPO_ROOT="/home/tc/Projects/tcOS-fedora"

  echo ""
  echo "→ Restoring browser profile configuration..."

  # ────────────────────────────────────────────────
  # 1. Ensure profile directory exists
  # ────────────────────────────────────────────────
  mkdir -p "$PROFILE_DIR"

  # ────────────────────────────────────────────────
  # 2. Restore bookmarks (if available)
  # ────────────────────────────────────────────────
  if [ -f "${REPO_ROOT}/configs/chromium-bookmarks.json" ]; then
    if [ ! -f "${PROFILE_DIR}/Bookmarks" ]; then
      echo "→ Installing default bookmarks..."
      cp "${REPO_ROOT}/configs/chromium-bookmarks.json" "${PROFILE_DIR}/Bookmarks"
      echo "  ✓ Bookmarks restored"
    else
      echo "→ Bookmarks already exist (skipping to preserve user data)"
    fi
  fi

  # ────────────────────────────────────────────────
  # 3. Open extension installation pages
  # ────────────────────────────────────────────────
  if [ -f "${REPO_ROOT}/configs/chromium-extensions.txt" ]; then
    echo "→ Preparing extensions for installation..."

    # Read extension URLs from manifest (skip comments and empty lines)
    local EXTENSION_URLS=()
    while IFS='|' read -r ext_id ext_name ext_url; do
      # Skip comments and empty lines
      [[ "$ext_id" =~ ^#.*$ ]] && continue
      [[ -z "$ext_id" ]] && continue

      # Trim whitespace
      ext_url=$(echo "$ext_url" | xargs)
      EXTENSION_URLS+=("$ext_url")
    done < "${REPO_ROOT}/configs/chromium-extensions.txt"

    # Open browser with all extension pages
    if [ ${#EXTENSION_URLS[@]} -gt 0 ]; then
      echo "→ Opening ${#EXTENSION_URLS[@]} extension page(s) in browser..."
      nohup "$BROWSER_COMMAND" "${EXTENSION_URLS[@]}" >/dev/null 2>&1 &
      sleep 2
      echo "  ✓ Extension pages opened"
    fi
  fi

  echo "→ Profile restoration complete"
}

# ════════════════════════════════════════════════════════════
# Export function for sourcing
# ════════════════════════════════════════════════════════════
export -f restore_chromium_profile
