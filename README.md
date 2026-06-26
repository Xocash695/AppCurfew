# AppCurfew

AppCurfew is a server-side API built with Swift Vapor that lets a parent 
manage screen time limits for specific applications on a child's Linux 
machine.

## How It Works

- A parent creates an account and registers child profiles
- Each child profile receives a unique, non-expiring API key
- The child's machine runs a script that authenticates with this API key
- The script queries the server to check which apps are currently allowed
- Based on the response, the script can block or allow specific applications

## Tech Stack

- **Vapor** — Swift web framework
- **Fluent** — ORM, backed by SQLite
- **Bcrypt** — password hashing for parent accounts

## Status

🚧 Work in progress — currently building out authentication 
(parent registration/login) before adding child profiles and API key access.

💧 A project built with the Vapor web framework.

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

### See more

- [Vapor Website](https://vapor.codes)
- [Vapor Documentation](https://docs.vapor.codes)
- [Vapor GitHub](https://github.com/vapor)
- [Vapor Community](https://github.com/vapor-community)


# Running with apple Containers

container run --rm --name container-local-test --publish 8080:8080 \
  --env SQLITE_FILEPATH=/app/db.sqlite \
  container-local-test
