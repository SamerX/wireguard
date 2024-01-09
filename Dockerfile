# Build environment
FROM golang:alpine3.18 AS build-env

# Install dependencies
RUN apk add --no-cache git gcc

# Clone wgrest repository
RUN git clone https://github.com/suquant/wgrest /app
WORKDIR /app

# Build wgrest
RUN export appVersion=$(git describe --tags `git rev-list -1 HEAD`) && \
    CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
      -ldflags "-X main.appVersion=$appVersion" \
      -o wgrest cmd/wgrest-server/main.go

# Final image
FROM alpine:3.18

RUN mkdir /app
RUN mkdir -p /var/lib/wgrest/v1

# Install WireGuard
RUN apk add --no-cache wireguard-tools sudo

RUN addgroup -g 1000 wireguard && \
  adduser -u 1000 -G wireguard -h /app/wireguard -D wireguard && \
  echo '%wheel ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/wheel && \
  adduser wireguard wheel

USER wireguard
WORKDIR /app/wireguard

# Copy Entrypoint script
COPY Entrypoint.sh ./Entrypoint.sh

# Copy wgrest binary
COPY --from=build-env /app/wgrest /app/wgrest
# Expose port
EXPOSE 51800/tcp
EXPOSE 51820/udp

# Set entrypoint to run wgrest and Entrypoint.sh
ENTRYPOINT ["/bin/sh", "-c", "/app/wgrest --listen '127.0.0.1:51800' && ./Entrypoint.sh"]
