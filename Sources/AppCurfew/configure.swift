import Fluent
import FluentSQLiteDriver
import Vapor

// configures your application
public func configure(_ app: Application) async throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    app.passwords.use(.bcrypt) // use bcrypt to encrypt the passwords
    app.databases.use(.sqlite(.file("db.sqlite")), as: .sqlite) // use sqlite to store the passwords
    app.migrations.add(CreateUser())
    app.migrations.add(CreateUserToken())
    app.migrations.add(CreateChildProfile()) // creating the child profilez
    app.migrations.add(CreateAllowedApp()) // allowing certain apps
    try app.register(collection: AllowedAppController()) // the controler for allowed apps
    try await app.autoMigrate()
    // register routes
    try routes(app)
}
