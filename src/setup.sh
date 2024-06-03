#!/bin/bash

if [[ -z "${CLOUDFLARED_TOKEN}" ]]; then
    read -p "Enter Cloudflared token: " CLOUDFLARED_TOKEN
fi

PODMAN_USER="jdgregson-browser-user"
SVC_HOST_NAME="browser.jdgregson.com"
PKG_NAME="jdgregson-browser-host"

# Green and red echo
gecho() { echo -e "\033[1;32m$1\033[0m"; }
recho() { echo -e "\033[1;31m$1\033[0m"; }

if [ ! -f "/etc/lsb-release" ] || [ -z "$(grep '22.04' /etc/lsb-release)" ]; then
    recho "ERROR: $PKG_NAME only supports Ubuntu Server 22.04"
    exit 1
fi

gecho "Creating and configuring user..."
if [ ! -d "/home/$PODMAN_USER" ]; then
    gecho "Creating user $PODMAN_USER..."
    useradd -m "$PODMAN_USER"
fi
loginctl enable-linger "$PODMAN_USER"

gecho "Downloading repo..."
if [ -d "/opt/$PKG_NAME" ]; then
    mv "/opt/$PKG_NAME" "/opt/$PKG_NAME.$(uuidgen)"
fi
git clone "https://github.com/jdgregson/$PKG_NAME.git" "/opt/$PKG_NAME"

gecho "Generating self-signed TLS certificate..."
mkdir "/opt/$PKG_NAME/src/nginx/ssl"
openssl req \
  -x509 \
  -newkey rsa:4096 \
  -keyout "/opt/$PKG_NAME/src/nginx/ssl/$SVC_HOST_NAME.key" \
  -out "/opt/$PKG_NAME/src/nginx/ssl/$SVC_HOST_NAME.crt" \
  -sha256 \
  -days 3650 \
  -nodes \
  -subj "/C=US/ST=Washington/L=Seattle/O=jdgregson/OU=InfrastructureEngineering/CN=$SVC_HOST_NAME"

gecho "Installing updates and dependencies..."
apt-get update
NEEDRESTART_MODE=a apt-get upgrade --yes
NEEDRESTART_MODE=a apt-get install --yes \
    podman \
    nginx

gecho "Deploying cloudflared..."
if [[ -z "$(which cloudflared)" ]]; then
    DEPLOY_DIR=$(mktemp -d)
    curl -L --output "$DEPLOY_DIR/cloudflared.deb" \
        "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb"
    dpkg -i "$DEPLOY_DIR/cloudflared.deb"
    rm -fr "$DEPLOY_DIR"
fi
cloudflared service install "$CLOUDFLARED_TOKEN"

gecho "Configuring services..."
systemctl stop nginx
rm "/etc/nginx/nginx.conf"
ln -T "/opt/$PKG_NAME/src/nginx/nginx.conf" "/etc/nginx/nginx.conf"
systemctl start nginx

gecho "Starting browser..."
su -c "/opt/$PKG_NAME/src/browser/start.sh" -m "$PODMAN_USER"
echo "0  4    * * *   $PODMAN_USER    /opt/$PKG_NAME/src/browser/reset.sh" >> "/etc/crontab"

gecho "Setting firewall rules..."
ufw deny 5000
ufw deny 6901
