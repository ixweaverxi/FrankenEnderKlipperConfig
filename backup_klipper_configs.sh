#!/usr/bin/env bash

set -e

#########################################
# USER SETTINGS
#########################################

CONFIG_DIR="$HOME/printer_data/config"
REPO_DIR="$HOME/klipper_config_backup"
GITHUB_REPO="git@github.com:ixweaverxi/FrankenEnderKlipperConfig.git"

#########################################

HOST=$(hostname)
DATE=$(date +"%Y-%m-%d %H:%M:%S")

echo "---- Klipper Git Backup ----"
echo "Host: $HOST"
echo "Time: $DATE"

# Ensure git exists
if ! command -v git &> /dev/null; then
    echo "Git is not installed."
    exit 1
fi

# Clone repo if missing
if [ ! -d "$REPO_DIR/.git" ]; then
    echo "Cloning repository..."
    git clone "$GITHUB_REPO" "$REPO_DIR"
fi

# Create gitignore if missing
if [ ! -f "$REPO_DIR/.gitignore" ]; then
cat <<EOF > "$REPO_DIR/.gitignore"
# Klipper logs
*.log

# Gcode files
*.gcode
*.gco

# timelapse
timelapse/

# cache
.cache/

# backup configs
printer-*.cfg

# system files
.DS_Store
EOF
fi

# Sync configs
echo "Syncing configuration files..."

rsync -av --delete \
    --exclude=".git" \
    --exclude="*.log" \
    --exclude="*.gcode" \
    --exclude="timelapse" \
    --exclude="printer-"\
    "$CONFIG_DIR/" "$REPO_DIR/config/"

cd "$REPO_DIR"

git add .

# Check if changes exist
if git diff --cached --quiet; then
    echo "No changes detected."
    exit 0
fi

echo "Changes detected."

git commit -m "Klipper config backup ($HOST) - $DATE"

echo "Pulling remote changes (rebase)..."
git pull --rebase

echo "Pushing to GitHub..."
git push

echo "Backup complete."
