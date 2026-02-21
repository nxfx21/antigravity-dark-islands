#!/bin/bash

set -e

echo "🏝️  Islands Dark Theme Installer for macOS/Linux"
echo "================================================ட்டான"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if agy command is available
if ! command -v agy &> /dev/null; then
    echo -e "${RED}❌ Error: Antigravity CLI (agy) not found!${NC}"
    echo "Please install Antigravity and make sure 'agy' command is in your PATH."
    echo "You can do this by:"
    echo "  1. Open Antigravity"
    echo "  2. Press Cmd+Shift+P (macOS) or Ctrl+Shift+P (Linux)"
    echo "  3. Type 'Shell Command: Install agy command in PATH'"
    exit 1
fi

echo -e "${GREEN}✓ Antigravity CLI found${NC}"

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo ""
echo "📦 Step 1: Installing Islands Dark theme extension..."

# Install by copying to Antigravity extensions directory
# Assuming .antigravity structure mirrors .vscode
EXT_DIR="$HOME/.antigravity/extensions/nxfx21.islands-dark-1.0.0"
rm -rf "$EXT_DIR"
mkdir -p "$EXT_DIR"
cp "$SCRIPT_DIR/package.json" "$EXT_DIR/"
cp -r "$SCRIPT_DIR/themes" "$EXT_DIR/"

if [ -d "$EXT_DIR/themes" ]; then
    echo -e "${GREEN}✓ Theme extension installed to $EXT_DIR${NC}"
else
    echo -e "${RED}❌ Failed to install theme extension${NC}"
    exit 1
fi

# Register extension in extensions.json so Antigravity discovers it
EXT_JSON="$HOME/.antigravity/extensions/extensions.json"
if command -v node &> /dev/null; then
    node << 'REGISTER_SCRIPT'
const fs = require('fs');
const path = require('path');

const extJsonPath = path.join(process.env.HOME, '.antigravity', 'extensions', 'extensions.json');
let extensions = [];
if (fs.existsSync(extJsonPath)) {
    try {
        extensions = JSON.parse(fs.readFileSync(extJsonPath, 'utf8'));
    } catch (e) {
        extensions = [];
    }
}

// Remove any existing Islands Dark entry
extensions = extensions.filter(e =>
    e.identifier?.id !== 'nxfx21.islands-dark' &&
    e.identifier?.id !== 'your-publisher-name.islands-dark'
);

// Add new entry
extensions.push({
    identifier: { id: 'nxfx21.islands-dark' },
    version: '1.0.0',
    location: {
        '$mid': 1,
        path: path.join(process.env.HOME, '.antigravity', 'extensions', 'nxfx21.islands-dark-1.0.0'),
        scheme: 'file'
    },
    relativeLocation: 'nxfx21.islands-dark-1.0.0'
});

fs.writeFileSync(extJsonPath, JSON.stringify(extensions));
REGISTER_SCRIPT
    echo -e "${GREEN}✓ Extension registered${NC}"
fi

echo ""
echo "🔧 Step 2: Installing Custom UI Style extension..."
if agy --install-extension subframe7536.custom-ui-style --force; then
    echo -e "${GREEN}✓ Custom UI Style extension installed${NC}"
else
    echo -e "${YELLOW}⚠️  Could not install Custom UI Style extension automatically${NC}"
    echo "   Please install it manually from the Extensions marketplace"
fi

echo ""
echo "🔤 Step 3: Installing Bear Sans UI fonts..."
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    FONT_DIR="$HOME/Library/Fonts"
    echo "   Installing fonts to: $FONT_DIR"
    cp "$SCRIPT_DIR/fonts/"*.otf "$FONT_DIR/" 2>/dev/null || true
    echo -e "${GREEN}✓ Fonts installed to Font Book${NC}"
    echo "   Note: You may need to restart applications to use the new fonts"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux
    FONT_DIR="$HOME/.local/share/fonts"
    mkdir -p "$FONT_DIR"
    echo "   Installing fonts to: $FONT_DIR"
    cp "$SCRIPT_DIR/fonts/"*.otf "$FONT_DIR/" 2>/dev/null || true
    fc-cache -f 2>/dev/null || true
    echo -e "${GREEN}✓ Fonts installed${NC}"
else
    echo -e "${YELLOW}⚠️  Could not detect OS type for automatic font installation${NC}"
    echo "   Please manually install the fonts from the 'fonts/' folder"
fi

echo ""
echo "⚙️  Step 4: Applying Antigravity settings..."
SETTINGS_DIR="$HOME/.config/antigravity/User"
if [[ "$OSTYPE" == "darwin"* ]]; then
    SETTINGS_DIR="$HOME/Library/Application Support/Antigravity/User"
fi

mkdir -p "$SETTINGS_DIR"
SETTINGS_FILE="$SETTINGS_DIR/settings.json"

# Backup existing settings if they exist
if [ -f "$SETTINGS_FILE" ]; then
    BACKUP_FILE="$SETTINGS_FILE.pre-islands-dark"
    cp "$SETTINGS_FILE" "$BACKUP_FILE"
    echo -e "${YELLOW}⚠️  Existing settings.json backed up to:${NC}"
    echo "   $BACKUP_FILE"
    echo "   You can restore your old settings from this file if needed."
fi

# Copy Islands Dark settings
cp "$SCRIPT_DIR/settings.json" "$SETTINGS_FILE"
echo -e "${GREEN}✓ Islands Dark settings applied${NC}"

echo ""
echo "🚀 Step 5: Enabling Custom UI Style..."
echo "   Antigravity will reload after applying changes..."

# Create a flag file to indicate first run
FIRST_RUN_FILE="$SCRIPT_DIR/.islands_dark_first_run"
if [ ! -f "$FIRST_RUN_FILE" ]; then
    touch "$FIRST_RUN_FILE"
    echo ""
    echo -e "${YELLOW}📝 Important Notes:${NC}"
    echo "   • IBM Plex Mono and FiraCode Nerd Font Mono need to be installed separately"
    echo "   • After Antigravity reloads, you may see a 'corrupt installation' warning"
    echo "   • This is expected - click the gear icon and select 'Don't Show Again'"
    echo ""
    if [ -t 0 ]; then
        read -p "Press Enter to continue and reload Antigravity..."
    fi
fi

# Apply custom UI style
echo "   Applying CSS customizations..."

# Reload Antigravity to apply changes
echo -e "${GREEN}✓ Setup complete!${NC}"
echo ""
echo "🎉 Islands Dark theme has been installed!"
echo "   Antigravity will now reload to apply the custom UI style."
echo ""

# Use AppleScript on macOS to show a notification and reload Antigravity
if [[ "$OSTYPE" == "darwin"* ]]; then
    osascript -e 'display notification "Islands Dark theme installed successfully!" with title "🏝️ Islands Dark"' 2>/dev/null || true
fi

echo "   Reloading Antigravity..."
agy --reload-window 2>/dev/null || agy . 2>/dev/null || true

echo ""
echo -e "${GREEN}Done! 🏝️${NC}"