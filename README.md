# jdgregson-browser-host

This repository contains the host configuration for hosts powering browser.jdgregson.com.

## Deployment
Define your Cloudflared token for the tunnel:
```
CLOUDFLARED_TOKEN="eyJhIjoiYz..."
```

Download and execute the setup script:
```
curl -s "https://raw.githubusercontent.com/jdgregson/jdgregson-browser-host/master/src/setup.sh" | sudo bash
```
