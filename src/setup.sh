#!/bin/bash

PODMAN_USER="jdgregson-browser-user"
SVC_HOST_NAME="browser.jdgregson.com"
PKG_NAME="jdgregson-browser-host"
TZ="America/Los_Angeles"

# Green and red echo
gecho() { echo -e "\033[1;32m$1\033[0m"; }
recho() { echo -e "\033[1;31m$1\033[0m"; }

if [ ! -f "/etc/lsb-release" ] || [ -z "$(grep '22.04' /etc/lsb-release)" ]; then
    recho "ERROR: $PKG_NAME only supports Ubuntu Server 22.04"
    exit 1
fi

gecho "Setting time zone to $TZ..."
timedatectl set-timezone "$TZ"

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

gecho "Configuring Podman CNI networks..."
sudo -u "$PODMAN_USER" bash << EONET
mkdir -p ~/.config/cni/net.d
cat > ~/.config/cni/net.d/kasm-bridge.conflist << EOF
{
  "cniVersion": "0.4.0",
  "name": "kasm-bridge",
  "plugins": [
    {
      "type": "bridge",
      "bridge": "cni-podman0",
      "isGateway": true,
      "ipMasq": true,
      "ipam": {
        "routes": [{"dst": "0.0.0.0/0"}],
        "type": "host-local",
        "subnet": "10.88.42.0/24"
      }
    }
  ]
}
EOF
podman network create kasm-bridge &>/dev/null || true
EONET

gecho "Downloading $PKG_NAME..."
if [ -d "/opt/$PKG_NAME" ]; then
    mv "/opt/$PKG_NAME" "/opt/$PKG_NAME.$(uuidgen)"
fi
git clone "https://github.com/jdgregson/$PKG_NAME.git" "/opt/$PKG_NAME"
chmod 755 "/opt/$PKG_NAME/src/browser/start.sh"

gecho "Generating self-signed TLS certificate..."
mkdir -p "/opt/$PKG_NAME/src/nginx/ssl"
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

gecho "Configuring Nginx service..."
systemctl stop nginx
rm "/etc/nginx/nginx.conf"
ln -T "/opt/$PKG_NAME/src/nginx/nginx.conf" "/etc/nginx/nginx.conf"
systemctl start nginx

gecho "Configuring browser service..."
cat << EOF > /etc/systemd/system/browser.service
[Unit]
Description=jdgregson-browser-host browser service
After=network.target

[Service]
Type=oneshot
User=jdgregson-browser-user
ExecStart=/opt/jdgregson-browser-host/src/browser/start.sh
ExecStop=/opt/jdgregson-browser-host/src/browser/stop.sh
RemainAfterExit=yes
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload

gecho "Starting browser..."
systemctl enable browser
systemctl start browser

gecho "Enabling browser auto-restart..."
cron_line="0  4    * * *   root    systemctl stop browser && systemctl start browser"
if [[ -z "$(grep "stop browser" /etc/crontab)" ]]; then
    echo "$cron_line" >> /etc/crontab
fi

gecho "Setting firewall rules..."
ufw allow in on lo proto tcp to 127.0.0.1 port 6901
ufw allow in on cni-podman0
ufw allow out on cni-podman0
ufw route allow out on cni-podman0 proto tcp to any port 443
ufw route allow out on cni-podman0 proto udp to any port 53
ufw --force enable

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
