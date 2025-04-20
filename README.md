# jdgregson-browser-host

This repository contains the host configuration for hosts powering browser.jdgregson.com.

## Deployment

### With new Cloudflared token
1. Define your Cloudflared token for the tunnel:
```
CLOUDFLARED_TOKEN="eyJhIjoiYz..."
```

2. Download and execute the setup script:
```
echo $CLOUDFLARED_TOKEN | xargs -I {} sudo bash -c "$(curl -s https://raw.githubusercontent.com/jdgregson/jdgregson-browser-host/master/src/setup.sh)" -- {}
```

### No Cloudflared changes
1. Download and execute the setup script:
```
curl -s https://raw.githubusercontent.com/jdgregson/jdgregson-browser-host/master/src/setup.sh | sudo bash
```

This can also be used to update jdgregson-browser-host on a running system.


### EC2 user-data script
1. Replace `eyJhIjoiY...` with your Cloudflared tunnel token:
```
#!/bin/bash
echo "eyJhIjoiY..." | xargs -I {} sudo bash -c "$(curl -s https://raw.githubusercontent.com/jdgregson/jdgregson-browser-host/master/src/setup.sh)" -- {}
```