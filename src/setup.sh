#!/bin/bash

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

gecho "Installing updates and dependencies..."
apt-get update
NEEDRESTART_MODE=a apt-get upgrade --yes
NEEDRESTART_MODE=a apt-get install --yes \
    podman \
    nginx

gecho "Creating and configuring Podman user..."
if [ ! -d "/home/$PODMAN_USER" ]; then
    gecho "Creating user $PODMAN_USER..."
    useradd -m "$PODMAN_USER"
fi
loginctl enable-linger "$PODMAN_USER"

gecho "Downloading $PKG_NAME..."
if [ -d "/opt/$PKG_NAME" ]; then
    mv "/opt/$PKG_NAME" "/opt/$PKG_NAME.$(uuidgen)"
fi
git clone "https://github.com/jdgregson/$PKG_NAME.git" "/opt/$PKG_NAME"
chmod 755 "/opt/$PKG_NAME/src/browser/start.sh"
chmod 755 "/opt/$PKG_NAME/src/browser/reset.sh"

gecho "Generating self-signed TLS certificate..."
mkdir "/opt/$PKG_NAME/src/nginx/ssl"
chmod 600 "/opt/$PKG_NAME/src/nginx/ssl"
openssl req \
  -x509 \
  -newkey rsa:4096 \
  -keyout "/opt/$PKG_NAME/src/nginx/ssl/$SVC_HOST_NAME.key" \
  -out "/opt/$PKG_NAME/src/nginx/ssl/$SVC_HOST_NAME.crt" \
  -sha256 \
  -days 3650 \
  -nodes \
  -subj "/C=US/ST=Washington/L=Seattle/O=jdgregson/OU=Infrastructure Engineering/CN=$SVC_HOST_NAME"

gecho "Configuring services..."
systemctl stop nginx
rm "/etc/nginx/nginx.conf"
ln -T "/opt/$PKG_NAME/src/nginx/nginx.conf" "/etc/nginx/nginx.conf"
systemctl start nginx

gecho "Starting browser..."
sudo su "$PODMAN_USER" --shell /bin/bash --login -c "/opt/$PKG_NAME/src/browser/start.sh"
cron_line="0  4    * * *   $PODMAN_USER    /opt/$PKG_NAME/src/browser/start.sh"
if [[ -z "$(grep "$PKG_NAME" /etc/crontab)" ]]; then
    echo "$cron_line" >> /etc/crontab
fi

gecho "Setting firewall rules..."
ufw deny 5000
ufw deny 6901

if [[ "${1}" ]]; then
    if [[ -z "$(which cloudflared)" ]]; then
        gecho "Installing cloudflared..."
        INSTALL_DIR=$(mktemp -d)
        curl -L --output "$INSTALL_DIR/cloudflared.deb" \
            "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb"
        dpkg -i "$INSTALL_DIR/cloudflared.deb"
        rm -fr "$INSTALL_DIR"
    else
        cloudflared service uninstall
    fi
    cloudflared service install $1
fi
