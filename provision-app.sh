#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# ==========================================
# CONFIGURATION
# ==========================================
APP_NAME="sparta-tictactoe"                      # Name for your app in PM2
APP_DIR="$HOME/app"                              # Your app folder in home directory
ZIP_FILE="$HOME/nodejs20-sparta-tictactoe-v1.zip"  # Your actual zip file
NODE_VERSION="20"                                # Node.js major version
PORT="3000"
echo "==> Starting deployment for $APP_NAME..."

# ==========================================
# 1. ENSURE DEPENDENCIES ARE INSTALLED
# ==========================================
echo "==> Updating apt and checking system packages..."
sudo apt-get update -y
sudo apt-get install -y curl unzip git

# Install Node.js & npm if missing or outdated
if ! command -v node &> /dev/null || [[ $(node -v | cut -d'v' -f2 | cut -d'.' -f1) -lt $NODE_VERSION ]]; then
    echo "==> Installing Node.js v${NODE_VERSION}..."
    curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | sudo -E bash -
    sudo apt-get install -y nodejs
else
    echo "==> Node.js $(node -v) is already installed."
fi

# Install PM2 globally if missing
if ! command -v pm2 &> /dev/null; then
    echo "==> Installing PM2 globally..."
    sudo npm install -g pm2
else
    echo "==> PM2 is already installed ($(pm2 --version))."
fi

# ==========================================
# 2. EXTRACT ZIP INTO APP DIRECTORY
# ==========================================
echo "==> Preparing project folder at $APP_DIR..."
mkdir -p "$APP_DIR"

if [ -f "$ZIP_FILE" ]; then
    echo "==> Extracting $ZIP_FILE into $APP_DIR..."
    unzip -qo "$ZIP_FILE" -d "$APP_DIR"
else
    echo "Warning: $ZIP_FILE not found. Using existing files in $APP_DIR."
fi

cd "$APP_DIR"

# Verification: Check if package.json exists
if [ ! -f "package.json" ]; then
    echo "Error: package.json not found in $APP_DIR! Check if the zip extracted into a subfolder." >&2
    exit 1
fi

# ==========================================
# 3. INSTALL NPM DEPENDENCIES
# ==========================================
echo "==> Installing project npm dependencies..."
if [ -f "package-lock.json" ]; then
    npm ci
else
    npm install
fi

# ==========================================
# 4. MANAGE APP VIA PM2 (IDEMPOTENT)
# ==========================================
echo "==> Configuring and starting application with PM2..."

if pm2 describe "$APP_NAME" > /dev/null 2>&1; then
    echo "==> App is already running. Reloading with zero downtime..."
    pm2 reload "$APP_NAME"
else
    echo "==> Starting app for the first time..."
    # Using index.js since it handles server.listen()
    pm2 start index.js --name "$APP_NAME"
fi

# Save current process state
pm2 save

# ==========================================
# 5. CONFIGURE SYSTEMD STARTUP
# ==========================================
PM2_STARTUP_CMD=$(pm2 startup systemd -u $USER --hp $HOME | grep -o "sudo env.*" || true)
if [ -n "$PM2_STARTUP_CMD" ]; then
    echo "==> Registering PM2 systemd startup service..."
    eval "$PM2_STARTUP_CMD"
fi

echo "==> Deployment complete! Your app is running on $PORT."
