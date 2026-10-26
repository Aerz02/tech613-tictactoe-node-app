#!/bin/bash

# Exit immediately if any command fails
set -e

# ==========================================
# CONFIGURATION
# ==========================================
APP_NAME="sparta-tictactoe"
REPO_URL="https://github.com/Aerz02/tech613-tictactoe-node-app.git"
REPO_DIR="tech613-tictactoe-node-app"
ZIP_FILE="/home/ubuntu/$REPO_DIR/nodejs20-sparta-tictactoe-v1.zip"
APP_DIR="/home/ubuntu/$REPO_DIR/app"

echo "==> Starting deployment for $APP_NAME..."

# ==========================================
# 1. INSTALL ESSENTIAL SYSTEM PACKAGES
# ==========================================
# export DEBIAN_FRONTEND=noninteractive
sudo apt-get update -y
sudo apt-get install -y curl unzip git nginx


# ==========================================
# 2. INSTALL NODE.JS 20 & PM2
# ==========================================
if ! command -v node &> /dev/null; then
    echo "==> Installing Node.js v20..."
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    sudo apt-get install -y nodejs
fi

if ! command -v pm2 &> /dev/null; then
    echo "==> Installing PM2 globally..."
    sudo npm install -g pm2
fi

# ==========================================
# 3. CLONE REPOSITORY & EXTRACT APP
# ==========================================
echo "==> Cloning repository..."
cd /home/ubuntu
rm -rf "$REPO_DIR"
git clone "$REPO_URL"
cd "$REPO_DIR"

echo "==> Extracting project zip..."
unzip -qo "$ZIP_FILE" -d "/home/ubuntu/$REPO_DIR"

# ==========================================
# 4. INSTALL NPM DEPENDENCIES & START APP
# ==========================================
cd "$APP_DIR"
echo "==> Installing npm packages..."
npm install

echo "==> Starting application with PM2..."
pm2 delete "$APP_NAME" || true
pm2 start index.js --name "$APP_NAME"
pm2 save

# ==========================================
# 5. CONFIGURE NGINX REVERSE PROXY
# ==========================================
echo "==> Configuring Nginx Reverse proxy"
sudo apt install sed
sudo sed -i 's|try_files \$uri \$uri/ =404;|proxy_pass http://localhost:3000;|' /etc/nginx/sites-available/default
grep proxy_pass /etc/nginx/sites-available/default
sudo nginx -t
sudo systemctl restart nginx

echo "==> deployment complete!"
