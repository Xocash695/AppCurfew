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
    
    struct LoginFormData: Content {
        var username: String
        var password: String
    }
    app.post("session-login") { req async throws -> Response in
        let form = try req.content.decode(LoginFormData.self)
        print("Attempting login for username: \(form.username)")
        
        guard let user = try await User.query(on: req.db)
            .filter(\User.$username == form.username)
            .first()
        else {
            print("User not found")
            return try await req.view.render("login", ["error": "Invalid username or password"]).encodeResponse(for: req)
        }
        print("User found: \(user.username)")
        
        guard try user.verify(password: form.password) else {
            print("Password verification failed")
            return try await req.view.render("login", ["error": "Invalid username or password"]).encodeResponse(for: req)
        }
        print("Login successful")
        
        req.auth.login(user)
        req.session.authenticate(user)

    
        
        return req.redirect(to: "/dashboard")
    }
    app.get("dashboard") { req async throws -> View in
      
        let user = try req.auth.require(User.self)
        
        let children = try await ChildProfile.query(on: req.db)
            .filter(\.$parent.$id == user.requireID())
            .all()
        
        return try await req.view.render("dashboard", ["children": children])
    }
    
    struct CreateChildFormData: Content {
        var name: String
    }

    app.post("dashboard", "children") { req async throws -> Response in
        let user = try req.auth.require(User.self)
        let form = try req.content.decode(CreateChildFormData.self)
        
        let apiKey = [UInt8].random(count: 32).base64
        let child = ChildProfile(name: form.name, apiKey: apiKey, userID: try user.requireID())
        try await child.save(on: req.db)
        
        return req.redirect(to: "/dashboard")
    }
    
    struct ChildPageContext: Encodable {
        var child: ChildProfile
        var apps: [AllowedApp]
    }
    app.get("children", ":childID") { req async throws -> View in
        let user = try req.auth.require(User.self)
        
        guard let childID = req.parameters.get("childID", as: UUID.self),
              let child = try await ChildProfile.find(childID, on: req.db),
              try child.$parent.id == user.requireID()
        else {
            throw Abort(.notFound)
        }
        
        let apps = try await AllowedApp.query(on: req.db)
            .filter(\.$childProfile.$id == child.requireID())
            .all()
        
        return try await req.view.render("child", ChildPageContext(child: child, apps: apps))
    }
    
    struct AddAppFormData: Content {
        var appIdentifier: String
        var dailyLimitSeconds: Int?
    }

    app.post("children", ":childID", "allowed-apps") { req async throws -> Response in
        let user = try req.auth.require(User.self)
        
        guard let childID = req.parameters.get("childID", as: UUID.self),
              let child = try await ChildProfile.find(childID, on: req.db),
              try child.$parent.id == user.requireID()
        else {
            throw Abort(.notFound)
        }
        
        let form = try req.content.decode(AddAppFormData.self)
        let app = AllowedApp(appIdentifier: form.appIdentifier, childProfileID: try child.requireID(), dailyLimitSeconds: form.dailyLimitSeconds)
        try await app.save(on: req.db)
        
        return req.redirect(to: "/children/\(childID)")
    }
}

