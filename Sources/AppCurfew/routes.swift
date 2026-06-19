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
    let protected = app.grouped(UserAuthenticator())
    protected.post("login") { req -> String in
        try req.auth.require(User.self).name
    }
}

