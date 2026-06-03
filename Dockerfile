FROM alpine:3.21

RUN apk add --no-cache \
    chromium \
    nss \
    freetype \
    harfbuzz \
    ca-certificates \
    ttf-freefont \
    font-noto-emoji

RUN addgroup -S chromium && adduser -S -G chromium chromium
USER chromium
WORKDIR /home/chromium

ENTRYPOINT ["chromium-browser", \
    "--no-sandbox", \
    "--disable-dev-shm-usage", \
    "--disable-gpu"]
