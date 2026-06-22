import Vapor

func routes(_ app: Application) throws {
    app.get { req async in
        "It works!"
    }

    app.get("hello") { req async -> String in
        "Hello, world!"
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
        let user = try req.auth.require(User.self) // cause we might need to toss an error if no user got authenticated
        
        // generating 32 random bytes
        let tokenValue = [UInt8].random(count: 32).base64  // base64 is safe way of encoding raw bytes as safe printable charters
        let token = UserToken(value: tokenValue, userID: try user.requireID()) //
        
        try await token.save(on: req.db) // takes time to save to the database
        
        return token // return the token we created
    }
    
    
    let tokenProtected = app.grouped(UserToken.authenticator()) // learning how to make a protected end point
    tokenProtected.get("me") { req -> String in
        try req.auth.require(User.self).name
    }
    
    try app.register(collection: ChildProfileController())
}

