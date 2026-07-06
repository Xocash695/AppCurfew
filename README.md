# AppCurfew

AppCurfew is an open-source, self-hosted screen time / child-device
management platform. A parent runs the server, creates an account, and
manages screen time limits for their children's apps from a web dashboard.
Enforcement happens on the child's device via a client that talks to
AppCurfew's open API — the server doesn't care what platform that client
runs on, or what language it's written in.

A premade, ready-to-use client already exists for **Linux + Flatpak**:
**[appcurfew-agent](https://github.com/Xocash695/appcurfew-agent)**. Install
it with:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/Xocash695/appcurfew-agent/main/install.sh)"
```

For any other platform (macOS, Windows, Android, or any other Linux app
sandboxing system), the API is fully open — build a client for whatever you
need to manage, using the same endpoints the Linux agent uses.

## How It Works

- A parent registers an account and logs in (via the web dashboard, or the API directly)
- The parent creates a **child profile**, which receives a unique, permanent API key
- The parent configures which apps that child can use, with any combination of:
  - a daily time limit (e.g. 30 minutes/day)
  - specific allowed days of the week
  - a specific time-of-day window (e.g. only 5pm–8pm)
  - a manual "bypass" toggle to temporarily lift all restrictions on an app
- A client running on the child's device authenticates with the child's API
  key, polls the server for the current allow-list, reports which apps are
  installed, and reports usage as apps run. The server does all the rule
  evaluation — the client's only job is to ask "what's allowed right now?"
  and act on the answer. That split is what makes the platform genuinely
  swappable: the Linux/Flatpak agent is a small, focused piece of
  platform-specific code sitting on top of the same API any other client
  would use.

## What's Built

**Parent accounts**
- Registration and login, both via a web session (cookie-based) and a JSON API (Bearer tokens, 1-day expiry)
- Change password, delete account (with full cascading cleanup of owned data)
- Password reset via a one-time code (currently printed to the server console in place of an email system — the plaintext password itself is never stored or recoverable, only a Bcrypt hash)
- The first account ever registered becomes an admin, who can globally disable/enable new registrations — useful for a self-hosted instance you don't want strangers signing up to

**Child profiles**
- Created and managed from the dashboard, each with its own permanent API key
- Full CRUD on allowed apps: add, edit, remove
- Daily time limits, day-of-week restrictions, time-of-day windows, and a manual bypass switch, usable independently or together
- Installed-app reporting, so a parent picks apps from a dropdown of what's actually on the child's device instead of typing raw identifiers by hand

**Web dashboard**
- Server-rendered with Leaf, styled with Tailwind
- Landing, login, registration, password reset, dashboard, per-child management, and account settings pages
- Live-updating allowed-apps view (HTMX polling) — no manual refresh needed to see usage count down

**Official Linux client** — [appcurfew-agent](https://github.com/Xocash695/appcurfew-agent)
- Written in Swift, runs as a systemd service
- Detects installed and running Flatpak apps, reports usage, blocks anything not currently allowed
- Supports multiple children sharing one machine under separate Linux accounts, each fully isolated from the others
- One-command install script

## Tech Stack

- **Vapor** — Swift web framework
- **Fluent** + **SQLite** — ORM and database
- **Leaf** — server-rendered HTML templating for the web dashboard
- **Bcrypt** — password hashing
- **Tailwind CSS** (via CDN) + **HTMX** — styling and live updates

## Status

✅ Backend API — parent auth, child profiles, allowed-app rules engine, usage/installed-app reporting
✅ Web dashboard — full parent-facing UI for everything above
✅ Official Linux/Flatpak client — [appcurfew-agent](https://github.com/Xocash695/appcurfew-agent), fully working end to end
🧭 Clients for other platforms don't exist yet — the API is ready for them, contributions welcome

## Known Limitations

- **No email system.** Password reset codes are printed to the server console rather than emailed — fine for a self-hosted single-family instance, not yet suitable for a multi-tenant deployment.
- **Enforcement is only as good as the client running it.** The Linux agent runs as root specifically so a child can't stop it, but that assumes the child's own account doesn't have sudo/admin rights. This is a general limitation of client-side enforcement on any OS, not specific to AppCurfew.

## A Note on AI Usage

AppCurfew was built with Claude as a hands-on collaborator throughout —
explaining Vapor/Fluent/Leaf and Linux/Swift concepts, working through real
bugs together (a Vapor session-authentication issue, a Flatpak
per-user-sandboxing issue that silently broke enforcement, several others),
and in places directly generating and applying code changes via Claude in
Xcode once a design had been agreed on and understood. The architecture,
feature decisions, and debugging judgment throughout were mine; Claude was
the pair-programming partner and teacher. I'm noting this plainly because I
think it's a more honest and more interesting story than pretending
otherwise.

## Getting Started

To build the project using the Swift Package Manager, run the following command in the terminal from the root of the project:
```bash
swift build
```

To run the project and start the server, use the following command:
```bash
swift run
```

To execute tests, use the following command:
```bash
swift test
```

### Running with Docker (published image)

A prebuilt image is published automatically to GitHub Container Registry on
every push to `main`. No Swift toolchain required on the host — just Docker.

```bash
mkdir -p ~/appcurfew-data
sudo chown -R 999:999 ~/appcurfew-data

docker run -d --name appcurfew \
  --restart unless-stopped \
  -p 8080:8080 \
  -v ~/appcurfew-data:/app/data \
  -e SQLITE_FILEPATH=/app/data/db.sqlite \
  ghcr.io/xocash695/appcurfew:main
```

The `chown` step matters: the container runs as a non-root `vapor` user
(UID/GID 999), so the mounted host directory needs to be owned by that same
UID or the database file can't be created.

`--restart unless-stopped` keeps the server running across reboots. The
mounted directory keeps your data persistent across container updates —
pulling a newer image and recreating the container won't touch it.

### Running with Apple Containers

#### First, build the container
```bash
container build --tag container-local-test --file Dockerfile
```

#### To use a temporary database that resets each run
```bash
container run --rm --name container-local-test --publish 8080:8080 \
  --env SQLITE_FILEPATH=/app/db.sqlite \
  container-local-test
```

#### To provide your own persistent db file instead
```bash
container run --rm --name container-local-test --publish 8080:8080 \
  --volume /Users/akashkallumkal/Source/AppCurfew/db.sqlite:/app/db.sqlite \
  --env SQLITE_FILEPATH=/app/db.sqlite \
  container-local-test
```

### See more

- [Vapor Website](https://vapor.codes)
- [Vapor Documentation](https://docs.vapor.codes)
- [Vapor GitHub](https://github.com/vapor)
- [Vapor Community](https://github.com/vapor-community)
