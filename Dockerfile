FROM alpine:latest

RUN apk add --no-cache bash curl jq util-linux

# Copy binaries and script
COPY rport-arm64 /rport-arm64
COPY rport-amd64 /rport-amd64
COPY run.sh /run.sh

# Permissions
RUN chmod +x /rport-arm64 /rport-amd64 /run.sh

# Set entry point
CMD ["/run.sh"]
