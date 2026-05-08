#!/bin/bash
# Installer for prime-billing-statusbar.
# - Symlinks the plugin into SwiftBar's standard plugin folder
# - Copies the icon asset to ~/.config/prime-balance/assets/
# - Creates a stub for the API key file (which you then fill in)
# - Refreshes SwiftBar if it's running

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${HOME}/.config/prime-balance"
PLUGIN_DIR="${HOME}/Library/Application Support/SwiftBar/Plugins"
PLUGIN_SCRIPT="prime-balance.5s.sh"

# --- Sanity checks ----------------------------------------------------------
if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "error: this plugin is macOS only (uname is $(uname -s))." >&2
  exit 1
fi

if [[ ! -f "${REPO_DIR}/${PLUGIN_SCRIPT}" ]]; then
  echo "error: ${PLUGIN_SCRIPT} not found in ${REPO_DIR}." >&2
  exit 1
fi

# --- SwiftBar (advisory) ----------------------------------------------------
if [[ ! -d /Applications/SwiftBar.app ]]; then
  echo "note: SwiftBar.app not found in /Applications."
  echo "      Install it first: brew install --cask swiftbar"
  echo "      (continuing anyway so the file layout is ready)"
fi

# --- 1. Asset ---------------------------------------------------------------
mkdir -p "${CONFIG_DIR}/assets"
cp "${REPO_DIR}/assets/prime-logo-template.png" "${CONFIG_DIR}/assets/"
chmod 644 "${CONFIG_DIR}/assets/prime-logo-template.png"
echo "✓ icon  → ${CONFIG_DIR}/assets/prime-logo-template.png"

# --- 2. API key stub --------------------------------------------------------
if [[ ! -f "${CONFIG_DIR}/key" ]]; then
  umask 077
  printf '%s' 'PASTE_YOUR_PRIME_INTELLECT_API_KEY_HERE' > "${CONFIG_DIR}/key"
  chmod 600 "${CONFIG_DIR}/key"
  echo "✓ key   → ${CONFIG_DIR}/key  (placeholder — edit me)"
else
  echo "✓ key   → ${CONFIG_DIR}/key  (already exists, left untouched)"
fi

# --- 3. Plugin symlink ------------------------------------------------------
chmod +x "${REPO_DIR}/${PLUGIN_SCRIPT}"
mkdir -p "${PLUGIN_DIR}"
ln -sfn "${REPO_DIR}/${PLUGIN_SCRIPT}" "${PLUGIN_DIR}/${PLUGIN_SCRIPT}"
echo "✓ plug  → ${PLUGIN_DIR}/${PLUGIN_SCRIPT} → ${REPO_DIR}/${PLUGIN_SCRIPT}"

# --- 4. SwiftBar plugin folder pref + refresh ------------------------------
defaults write com.ameba.SwiftBar PluginDirectory "${PLUGIN_DIR}" >/dev/null
defaults write com.ameba.SwiftBar PluginDirectoryResolvedPath "${PLUGIN_DIR}" >/dev/null

if pgrep -x SwiftBar >/dev/null; then
  open "swiftbar://refreshallplugins" >/dev/null 2>&1 || true
  echo "✓ refresh signal sent to SwiftBar"
else
  echo "note: SwiftBar isn't running. Launch it with: open -a SwiftBar"
fi

echo
echo "Next: paste your Prime Intellect API key into ${CONFIG_DIR}/key and refresh SwiftBar."
echo "      (Right-click the menu-bar item → Refresh, or run: open 'swiftbar://refreshallplugins')"
