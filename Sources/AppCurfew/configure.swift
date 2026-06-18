import Vapor

// configures your application
public func configure(_ app: Application) async throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    app.passwords.use(.bcrypt)

    UserAuthenticator.storedPasswordHash = try app.password.hash("secret")

    // register routes
    try routes(app)
}
