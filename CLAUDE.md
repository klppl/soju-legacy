# CLAUDE.md - Project Guide for soju-legacy

## Project Overview

soju is a user-friendly IRC bouncer written in Go. It connects to upstream IRC servers on behalf of users and allows multiple clients to attach/detach while maintaining persistent connections and chat history.

Licensed under AGPLv3.

## Build & Run

```bash
# Build all binaries
make

# Build just the Go binaries (no man pages)
go build -v ./cmd/soju ./cmd/sojudb ./cmd/sojuctl

# Install (default PREFIX=/usr/local)
make install

# Build tags for optional features:
#   libsqlite3      - use system SQLite library
#   nosqlite        - disable SQLite support
#   moderncsqlite   - use pure-Go SQLite (no CGO)
#   pam             - enable PAM authentication
GOFLAGS="-tags=pam" make
```

## Testing

```bash
# Run all tests
go test -v ./...

# Run with PostgreSQL tests
export SOJU_TEST_POSTGRES="host=/run/postgresql dbname=soju"
go test -v ./...
```

## Code Style

- **Indentation:** Tabs (enforced by .editorconfig)
- **Formatting:** Must pass `gofmt` — CI runs `test -z $(gofmt -l .)`
- **Line length:** 80 chars max for markdown/docs
- **Charset:** UTF-8, LF line endings, final newline required

## Project Structure

```
cmd/soju/         Main bouncer daemon
cmd/sojudb/       Database management CLI (create-user, change-password)
cmd/sojuctl/      Admin control client (connects via Unix socket)
auth/             Authentication backends (internal, PAM, HTTP, OAuth2)
config/           Configuration parsing (scfg format)
database/         Database layer (SQLite, PostgreSQL) with migrations
msgstore/         Message storage backends (DB, filesystem, memory, ZNC logs)
xirc/             IRC protocol extensions and utilities
fileupload/       File upload backends (filesystem, HTTP)
identd/           Ident daemon implementation
doc/              Documentation and man page sources (.scd)
contrib/          Community resources (systemd, nginx, caddy, migration tools)
```

Core logic lives in root-level Go files:
- `server.go` — Server lifecycle and listener management
- `user.go` — Per-user state and event dispatcher goroutine
- `downstream.go` — Client (downstream) connection handling
- `upstream.go` — IRC server (upstream) connection handling
- `service.go` — BouncerServ IRC service commands
- `conn.go` — Connection primitives
- `irc.go` — IRC message utilities

## Architecture

- **One dispatcher goroutine per user** reads from `user.events` channel, avoiding race conditions
- **Ring buffer** per channel for bounded message history with multi-consumer support
- **Pluggable backends** via interfaces: database, message store, auth, file upload
- **Config format:** scfg (see `config.in` for defaults)

## CI

Uses sr.ht (`.build.yml`): builds on Alpine Linux, runs `go build`, `go test`, and `gofmt` checks. PostgreSQL tests included in CI.

## Dependencies

Go 1.24+. Key deps: `gopkg.in/irc.v4`, `go-scfg`, `go-sqlite3`, `lib/pq`, `coder/websocket`, `go-proxyproto`. Man pages require `scdoc`.
