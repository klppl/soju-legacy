# Build stage
FROM golang:alpine AS builder

# Install build dependencies
RUN apk add --no-cache git make scdoc build-base

WORKDIR /app

# Copy go mod and sum files
COPY go.mod go.sum ./
RUN go mod download

# Copy the source code
COPY . .

# Build the application
# We use the Makefile to ensure we use the same build flags as the project intended,
# but we can also just run go build if make is too complex. 
# The Makefile is simple enough.
RUN make soju sojuctl sojudb

# Runtime stage
FROM alpine:latest

# Install runtime dependencies
RUN apk add --no-cache ca-certificates

# Create a user for soju
RUN adduser -D -H -h /var/lib/soju soju

# Copy binaries from the builder stage
COPY --from=builder /app/soju /usr/bin/soju
COPY --from=builder /app/sojuctl /usr/bin/sojuctl
COPY --from=builder /app/sojudb /usr/bin/sojudb

# Set up the data directory
RUN mkdir -p /var/lib/soju && chown soju:soju /var/lib/soju
VOLUME /var/lib/soju

USER soju
WORKDIR /var/lib/soju

# Expose the default listener port
EXPOSE 6697

ENTRYPOINT ["/usr/bin/soju"]
