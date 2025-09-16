#!/usr/bin/env bash
# ------------------------------------------------------------------------------
#  Title   : Setup SSL (Let's Encrypt) for everestphones.com on EC2 (Nginx)
#  Author  : bidhan948
#  Purpose : Install Nginx + Certbot, configure reverse proxy to :8000,
#            and obtain HTTPS certs for everestphones.com + www
# ------------------------------------------------------------------------------

set -euo pipefail

DOMAIN="everestphones.com"
EMAIL="you@example.com"        # <-- change to your email (for expiry notices)
APP_PORT="8000"                # Your app is running on this port
APEX="$DOMAIN"
WWW="www.$DOMAIN"

echo "🚀 Starting SSL setup for $APEX and $WWW (proxy to :$APP_PORT) ..."

# --- Helpers ------------------------------------------------------------------
is_cmd() { command -v "$1" >/dev/null 2>&1; }

fail() {
  echo "❌ $*" >&2
  exit 1
}

# --- Install Nginx ------------------------------------------------------------
if is_cmd apt; then
  echo "🧩 Detected Ubuntu/Debian. Installing Nginx..."
  sudo apt update -y
  sudo apt install -y nginx
  NGINX_SITE_DIR="/etc/nginx/sites-available"
  NGINX_ENABLED_DIR="/etc/nginx/sites-enabled"
  NGINX_CONF_FILE="$NGINX_SITE_DIR/$DOMAIN"
elif is_cmd dnf; then
  echo "🧩 Detected Amazon Linux 2023 / RHEL (dnf). Installing Nginx..."
  sudo dnf install -y nginx
  NGINX_SITE_DIR="/etc/nginx/conf.d"
  NGINX_ENABLED_DIR=""
  NGINX_CONF_FILE="$NGINX_SITE_DIR/$DOMAIN.conf"
elif is_cmd yum; then
  echo "🧩 Detected Amazon Linux / RHEL (yum). Installing Nginx..."
  sudo yum install -y nginx
  NGINX_SITE_DIR="/etc/nginx/conf.d"
  NGINX_ENABLED_DIR=""
  NGINX_CONF_FILE="$NGINX_SITE_DIR/$DOMAIN.conf"
else
  fail "Unsupported OS (no apt/dnf/yum)."
fi

echo "🔧 Enabling and starting Nginx..."
sudo systemctl enable --now nginx

# --- Create/Update Nginx vhost ------------------------------------------------
if [ ! -f "$NGINX_CONF_FILE" ]; then
  echo "📝 Creating Nginx vhost: $NGINX_CONF_FILE"
  sudo tee "$NGINX_CONF_FILE" >/dev/null <<CONF
server {
    listen 80;
    server_name $APEX $WWW;

    client_max_body_size 20m;

    location / {
        proxy_pass http://127.0.0.1:$APP_PORT;
        proxy_http_version 1.1;

        proxy_set_header Host              \$host;
        proxy_set_header X-Real-IP         \$remote_addr;
        proxy_set_header X-Forwarded-For   \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;

        # WebSocket support
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
CONF

  # Debian/Ubuntu enables sites via sites-enabled symlink
  if [ -n "${NGINX_ENABLED_DIR}" ] && [ -d "${NGINX_ENABLED_DIR}" ]; then
    sudo ln -sf "$NGINX_CONF_FILE" "$NGINX_ENABLED_DIR/$DOMAIN"
    sudo rm -f "$NGINX_ENABLED_DIR/default" || true
  fi
else
  echo "ℹ️ Nginx vhost already exists: $NGINX_CONF_FILE (leaving as-is)"
fi

echo "🧪 Testing Nginx config..."
sudo nginx -t
echo "🔄 Reloading Nginx..."
sudo systemctl reload nginx

# --- Install Certbot ----------------------------------------------------------
if is_cmd apt; then
  # Snap on Ubuntu/Debian
  echo "📦 Installing Certbot via snap..."
  sudo snap install core && sudo snap refresh core
  sudo snap install --classic certbot
  sudo ln -sf /snap/bin/certbot /usr/bin/certbot
elif is_cmd dnf; then
  echo "📦 Installing Certbot (dnf)..."
  sudo dnf install -y certbot python3-certbot-nginx
elif is_cmd yum; then
  echo "📦 Installing Certbot (yum)..."
  sudo yum install -y certbot python3-certbot-nginx
fi

# --- Obtain certificates and auto-configure HTTPS -----------------------------
echo "🔐 Requesting Let's Encrypt certificates for $APEX and $WWW ..."
sudo certbot --nginx \
  -d "$APEX" -d "$WWW" \
  --redirect --agree-tos -m "$EMAIL" -n

echo "🧪 Verifying HTTPS..."
set +e
curl -sSfI "https://$APEX" >/dev/null
CURL_STATUS=$?
set -e
if [ "$CURL_STATUS" -eq 0 ]; then
  echo "✅ HTTPS is live on https://$APEX 🎉"
else
  echo "⚠️ Could not verify via curl. Check Nginx/certbot logs if needed."
fi

echo "⏱️ Checking auto-renew (systemd timer or cron)..."
systemctl list-timers | grep -i certbot || crontab -l 2>/dev/null | grep -i certbot || true

echo "✨ All done! — by @bidhan948  🙌"
echo "🌐 Domain: https://$APEX  |  Proxy target: 127.0.0.1:$APP_PORT"
echo "🪪 Certs managed by Certbot; renewal runs automatically."
echo "💡 Tip: Ensure EC2 Security Group allows TCP 80 & 443 from the internet."
