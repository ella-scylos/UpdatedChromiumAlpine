# UpdatedChromiumAlpine

Runs **Chromium 142.0.7444.59** inside an Alpine Linux 3.22 Docker container with X11 forwarding, so it displays on your host desktop. A `.desktop` launcher starts the container on demand — nothing runs until you click the icon.

## Files

| File | Purpose |
|------|---------|
| `Dockerfile` | Builds the Chromium image on Alpine 3.21 |
| `run-chromium-alpine.sh` | Launches the container with X11 forwarding |
| `chromium.png` | Desktop launcher icon (128×128) |

## Requirements

- Docker
- Linux with an X11 display server
- User in the `docker` group (the script handles this automatically via `sg docker`)

## Setup

**1. Build the image** (done automatically on first launch, or manually):
```bash
docker build -t chromium-alpine:142.0.7444.59 .
```

**2. Create a desktop launcher** — save the following as `~/Desktop/Chromium Alpine Docker.desktop`, then mark it trusted:
```ini
[Desktop Entry]
Version=1.0
Type=Application
Name=Chromium (Alpine Docker)
Exec=bash /path/to/run-chromium-alpine.sh
Icon=/path/to/chromium.png
Terminal=false
Categories=Network;WebBrowser;
```
```bash
chmod +x ~/Desktop/Chromium\ Alpine\ Docker.desktop
gio set ~/Desktop/Chromium\ Alpine\ Docker.desktop metadata::trusted true
```

**3. Click the icon** — Chromium opens. When you close it, the container stops and removes itself automatically.

## How it works

`run-chromium-alpine.sh`:
1. Auto-builds the image on first run if it doesn't exist
2. Runs `xhost +local:` to grant the container access to the host X server
3. Starts the container with `$DISPLAY`, `/tmp/.X11-unix`, and your host UID forwarded
4. Revokes `xhost +local:` immediately when Chromium closes

```bash
docker run --rm \
    -e DISPLAY="$DISPLAY" \
    -e HOME=/tmp \
    -v /tmp/.X11-unix:/tmp/.X11-unix \
    --user "$(id -u):$(id -g)" \
    --shm-size=256m \
    chromium-alpine
```

## Chromium flags

| Flag | Reason |
|------|--------|
| `--no-sandbox` | Required — Linux user namespaces are restricted inside Docker |
| `--disable-dev-shm-usage` | Docker's `/dev/shm` defaults to 64 MB; without this Chromium crashes on heavy pages |
| `--disable-gpu` | No GPU passthrough in this setup; avoids GPU-related startup errors |
