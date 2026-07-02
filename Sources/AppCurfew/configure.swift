import Fluent
import FluentSQLiteDriver
import Vapor
import Leaf

// configures your application
public func configure(_ app: Application) async throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    app.passwords.use(.bcrypt) // use bcrypt to encrypt the passwords
    
    let sqlitePath = Environment.get("SQLITE_FILEPATH") ?? "/Users/akashkallumkal/Source/AppCurfew/db.sqlite"
    app.databases.use(.sqlite(.file(sqlitePath)), as: .sqlite)
    app.views.use(.leaf)
    app.middleware.use(app.sessions.middleware)
    app.middleware.use(UserSessionAuthenticator())
    app.migrations.add(CreateUser())
    app.migrations.add(CreateUserToken())
    app.migrations.add(CreateChildProfile()) // creating the child profilez
    app.migrations.add(CreateAllowedApp()) // allowing certain apps
    app.leaf.cache.isEnabled = false // should disable during production
    app.migrations.add(CreateInstalledApp()) // report the installed apps on the system flatpaks
    app.migrations.add(CreateServerSettings()) // server-wide settings table
    app.migrations.add(SeedServerSettings()) // seed the single settings row
    try app.register(collection: AllowedAppController()) // the controller for allowed apps
    try await app.autoMigrate()
    // register routes
    try routes(app)
}
