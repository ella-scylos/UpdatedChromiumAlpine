# Notes

## Why Alpine instead of Debian?

Alpine produces a significantly smaller image (~200 MB compressed vs ~400 MB for Debian bookworm-slim). The Alpine `chromium` package is a proper apk — no Snap wrapper, no workarounds needed.

Alpine 3.23 ships Chromium 148.0.7778.178.

## Why `xhost +local:` instead of `xhost +local:docker`?

`+local:docker` grants X access only to the user named `docker`. The container process runs as your host user (via `--user $(id -u):$(id -g)`), so `+local:` (no name filter) is required to allow any local Unix socket connection regardless of username.

## Why `--user $(id -u):$(id -g)`?

The X server checks the UID of connecting processes. Running the container as your host UID makes the X server recognize it as a trusted local user. Without this flag the container runs as the Alpine `chromium` system user (a low UID), which the X server rejects.

## Why `-e HOME=/tmp`?

When the container runs as your host UID, the default `WORKDIR` (`/home/chromium`) is owned by the Alpine system user and is not writable. Chromium needs a writable home to create its profile directory and crash handler database. `/tmp` is always writable.

## Why mount `/dev/dri`?

Chromium 142 uses ANGLE for GL rendering, which requires access to the host's DRM graphics device. Without `--device=/dev/dri:/dev/dri`, Mesa fails with `Failed to query drm device` and the GPU compositor crashes, leaving a blank white window. The `--group-add` flags pass the host `video` and `render` group IDs so the container process has permission to open the devices.

## Why `--shm-size=256m`?

Docker's default shared memory (`/dev/shm`) is 64 MB. Chromium uses shared memory for rendering and crashes silently on memory-intensive pages without enough space. 256 MB is a safe minimum.

## Harmless dbus errors

On startup you may see:
```
Failed to connect to the bus: Failed to connect to socket /run/dbus/system_bus_socket
```
Safe to ignore. Docker containers don't run a system dbus by default. Chromium logs the failure and continues normally.

## docker group / permission issue

If you get `permission denied while trying to connect to the Docker daemon`, your shell session was started before your user was added to the `docker` group. Fix it by opening a new terminal or running:
```bash
newgrp docker
```
The `run-chromium-alpine.sh` script handles this automatically using `sg docker` as a fallback.

## Desktop launcher not opening (GNOME)

If double-clicking the `.desktop` file does nothing, GNOME hasn't marked it as trusted. Run:
```bash
gio set ~/Desktop/Chromium\ Alpine\ Docker.desktop metadata::trusted true
```

## Container name conflict

The launch script does not set a `--name` for the container, so Docker assigns a random name each run. This allows multiple instances and avoids the "container name already in use" error that occurs if you click the icon while a previous instance is still running.
