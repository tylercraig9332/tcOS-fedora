#!/usr/bin/env bash

set -euo pipefail

# ════════════════════════════════════════════════════════════
# Export Chromium-based Browser Profile Configuration
# ════════════════════════════════════════════════════════════
# Exports bookmarks and extension list from any Chromium-based browser
#
# Usage:
#   ./export-chromium-profile.sh [browser_config_dir]
#
# Examples:
#   ./export-chromium-profile.sh                                    # Auto-detect
#   ./export-chromium-profile.sh ~/.config/chromium                 # Chromium
#   ./export-chromium-profile.sh ~/.config/google-chrome            # Chrome
#   ./export-chromium-profile.sh ~/.config/BraveSoftware/Brave-Browser  # Brave
# ════════════════════════════════════════════════════════════

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
CONFIGS_DIR="${REPO_ROOT}/configs"

# ────────────────────────────────────────────────
# Detect browser config directory
# ────────────────────────────────────────────────
if [ $# -eq 0 ]; then
  echo "→ Auto-detecting Chromium-based browser..."

  # Check common locations in order of preference
  if [ -d "$HOME/.config/chromium/Default" ]; then
    BROWSER_CONFIG_DIR="$HOME/.config/chromium"
    BROWSER_NAME="Chromium"
  elif [ -d "$HOME/.config/google-chrome/Default" ]; then
    BROWSER_CONFIG_DIR="$HOME/.config/google-chrome"
    BROWSER_NAME="Google Chrome"
  elif [ -d "$HOME/.config/BraveSoftware/Brave-Browser/Default" ]; then
    BROWSER_CONFIG_DIR="$HOME/.config/BraveSoftware/Brave-Browser"
    BROWSER_NAME="Brave Browser"
  elif [ -d "$HOME/.config/microsoft-edge/Default" ]; then
    BROWSER_CONFIG_DIR="$HOME/.config/microsoft-edge"
    BROWSER_NAME="Microsoft Edge"
  else
    echo "ERROR: No Chromium-based browser profile found"
    echo ""
    echo "Searched locations:"
    echo "  - ~/.config/chromium"
    echo "  - ~/.config/google-chrome"
    echo "  - ~/.config/BraveSoftware/Brave-Browser"
    echo "  - ~/.config/microsoft-edge"
    echo ""
    echo "Usage: $0 <browser_config_dir>"
    exit 1
  fi

  echo "  Found: $BROWSER_NAME"
else
  BROWSER_CONFIG_DIR="$1"
  BROWSER_NAME="Custom"
fi

PROFILE_DIR="${BROWSER_CONFIG_DIR}/Default"

if [ ! -d "$PROFILE_DIR" ]; then
  echo "ERROR: Profile directory not found: $PROFILE_DIR"
  exit 1
fi

echo ""
echo "========================================"
echo "  Exporting Browser Profile Config"
echo "  Source: $BROWSER_NAME"
echo "========================================"
echo ""

# ────────────────────────────────────────────────
# 1. Export Bookmarks
# ────────────────────────────────────────────────
if [ -f "${PROFILE_DIR}/Bookmarks" ]; then
  echo "→ Exporting bookmarks..."
  cp "${PROFILE_DIR}/Bookmarks" "${CONFIGS_DIR}/chromium-bookmarks.json"

  # Count bookmarks
  BOOKMARK_COUNT=$(grep -o '"type": "url"' "${CONFIGS_DIR}/chromium-bookmarks.json" | wc -l)
  echo "  ✓ Exported ${BOOKMARK_COUNT} bookmarks"
else
  echo "→ No bookmarks file found (skipping)"
fi

# ────────────────────────────────────────────────
# 2. Export Extension List
# ────────────────────────────────────────────────
if [ -d "${PROFILE_DIR}/Extensions" ]; then
  echo "→ Exporting extension list..."

  # Create new manifest file
  cat > "${CONFIGS_DIR}/chromium-extensions.txt" << 'EOF'
# Chromium Extensions Manifest
# Format: extension_id | extension_name | chrome_web_store_url
# Lines starting with # are comments

EOF

  # List all extension IDs
  EXTENSION_COUNT=0
  for ext_dir in "${PROFILE_DIR}/Extensions"/*; do
    if [ -d "$ext_dir" ]; then
      EXT_ID=$(basename "$ext_dir")

      # Skip special directories
      [[ "$EXT_ID" == "Temp" ]] && continue

      # Try to get extension name from manifest
      EXT_NAME="Unknown Extension"
      MANIFEST_FILE=$(find "$ext_dir" -name "manifest.json" -type f | head -1)
      if [ -f "$MANIFEST_FILE" ]; then
        # Extract name from manifest (handle multi-line JSON)
        EXT_NAME=$(grep -A 1 '"name":' "$MANIFEST_FILE" | head -1 | sed 's/.*"name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
        # If name is a locale key, try to get from messages
        if [[ "$EXT_NAME" =~ ^__MSG_.*__$ ]]; then
          EXT_NAME="Extension ${EXT_ID:0:8}"
        fi
      fi

      # Add to manifest
      echo "${EXT_ID} | ${EXT_NAME} | https://chromewebstore.google.com/detail/${EXT_ID}" >> "${CONFIGS_DIR}/chromium-extensions.txt"
      EXTENSION_COUNT=$((EXTENSION_COUNT + 1))
    fi
  done

  echo "  ✓ Exported ${EXTENSION_COUNT} extension(s)"
else
  echo "→ No extensions directory found (skipping)"
fi

# ────────────────────────────────────────────────
# Summary
# ────────────────────────────────────────────────
echo ""
echo "========================================"
echo " Export complete! ✓"
echo ""
echo "Exported files:"
echo "  - ${CONFIGS_DIR}/chromium-bookmarks.json"
echo "  - ${CONFIGS_DIR}/chromium-extensions.txt"
echo ""
echo "Next steps:"
echo "  1. Review exported files"
echo "  2. Edit chromium-extensions.txt to add proper extension names/URLs"
echo "  3. Commit changes to your repo"
echo "  4. Future installations will restore these automatically"
echo "========================================"
