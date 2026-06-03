#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

run_chromium() {
    if ! docker image inspect chromium-alpine:142.0.7444.59 >/dev/null 2>&1; then
        docker build -t chromium-alpine:142.0.7444.59 "$SCRIPT_DIR"
    fi

    xhost +local: >/dev/null 2>&1

    docker run --rm \
        -e DISPLAY="$DISPLAY" \
        -e HOME=/tmp \
        -v /tmp/.X11-unix:/tmp/.X11-unix \
        --device=/dev/dri:/dev/dri \
        --group-add "$(stat -c '%g' /dev/dri/renderD128)" \
        --group-add "$(stat -c '%g' /dev/dri/card1)" \
        --user "$(id -u):$(id -g)" \
        --shm-size=256m \
        chromium-alpine:142.0.7444.59

    xhost -local: >/dev/null 2>&1
}

if id -nG | grep -qw docker; then
    run_chromium
else
    sg docker -c "SCRIPT_DIR='$SCRIPT_DIR'; DISPLAY='$DISPLAY'; $(declare -f run_chromium); run_chromium"
fi
