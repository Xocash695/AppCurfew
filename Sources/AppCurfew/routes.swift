import Vapor
import Fluent
func routes(_ app: Application) throws {
    app.get { req async in
        "It works!"
    }

    app.get("hello") { req async -> String in
        "Hello, world!"
    }
    app.get("login") { req async throws -> View in
        return try await req.view.render("login", ["name": "Leaf"])
    }
    
    try app.register(collection: UserController())  // the registration
    // how to get it say the name?
    app.get("hello", ":name") { req async throws -> String in
        guard let name = req.parameters.get("name") else {
            throw Abort(.badRequest, reason: "Missing name parameter")
        }
        return "Hello, \(name)!"
    }
    let protected = app.grouped(UserAuthenticator()) // call the user authenticator
    protected.post("login") { req async throws -> UserToken in
        let user = try req.auth.require(User.self)
        
        let tokenValue = [UInt8].random(count: 32).base64
        let expiry = Date().addingTimeInterval(60 * 60 * 24)  // 1 day from now
        let token = UserToken(value: tokenValue, userID: try user.requireID(), expiresAt: expiry)
        
        try await token.save(on: req.db)
        
        return token
    }
    
    
    let tokenProtected = app.grouped(UserToken.authenticator()) // learning how to make a protected end point
    tokenProtected.get("me") { req -> String in
        try req.auth.require(User.self).name
    }
    
    try app.register(collection: ChildProfileController())
    
    try app.register(collection: WebController())
    
    try app.register(collection: InstalledAppController())
}

