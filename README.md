# AppCurfew

AppCurfew is a self-hosted screen time manager for **Linux** machines. A parent
runs the server, creates an account, and manages screen time limits for
specific **Flatpak** applications on each of their children's devices — all
from a web dashboard.

Enforcement happens on the child's machine via a lightweight agent that polls
the server and blocks apps that aren't currently allowed. The agent itself is
still in progress (see [Status](#status) below) — everything else described
here is built and working.

## How It Works

- A parent registers an account and logs in (via the web dashboard, or the API directly)
- The parent creates a **child profile**, which receives a unique, permanent API key
- The parent configures which apps that child can use, with any combination of:
  - a daily time limit (e.g. 30 minutes/day)
  - specific allowed days of the week
  - a specific time-of-day window (e.g. only 5pm–8pm)
  - a manual "bypass" toggle to temporarily lift all restrictions on an app
- The child's machine (once the agent is built) authenticates with the child's
  API key, polls the server for the current allow-list, reports which Flatpak
  apps are installed, and reports usage as apps run — the server does all the
  rule evaluation; the client just asks "what's allowed right now?"

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
- Installed-app reporting, so a parent picks apps from a dropdown of what's actually on the child's machine instead of typing raw Flatpak identifiers

**Web dashboard**
- Server-rendered with Leaf, styled with Tailwind
- Landing, login, registration, password reset, dashboard, per-child management, and account settings pages

## Tech Stack

- **Vapor** — Swift web framework
- **Fluent** + **SQLite** — ORM and database
- **Leaf** — server-rendered HTML templating for the web dashboard
- **Bcrypt** — password hashing
- **Tailwind CSS** (via CDN) — styling

## Status

✅ Backend API — parent auth, child profiles, allowed-app rules engine, usage/installed-app reporting
✅ Web dashboard — full parent-facing UI for everything above
🚧 **Client agent** — the piece that actually runs on the child's Linux machine and enforces the rules (checking `flatpak list`, polling the API, blocking disallowed apps) is still being built. Until it exists, AppCurfew's server correctly computes and serves the rules, but nothing is enforced on a real machine yet.

## A Note on AI Usage

AppCurfew was built in collarboration with claude. 


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

### Running with Apple Containers

```bash
container run --rm --name container-local-test --publish 8080:8080 \
  --env SQLITE_FILEPATH=/app/db.sqlite \
  container-local-test
```

### See more

- [Vapor Website](https://vapor.codes)
- [Vapor Documentation](https://docs.vapor.codes)
- [Vapor GitHub](https://github.com/vapor)
- [Vapor Community](https://github.com/vapor-community)
