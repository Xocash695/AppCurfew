//
//  WebController.swift
//  AppCurfew
//
//  Created by Akash Kallumkal on 2026-06-26.
//

import Vapor
import Fluent
import Leaf

struct WebController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
            routes.get("login", use: showLogin)
            routes.post("session-login", use: sessionLogin)
            routes.get("dashboard", use: dashboard)
            routes.post("dashboard", "children", use: createChild)
            routes.get("children", ":childID", use: showChild)
            routes.post("dashboard", "children", ":childID", "allowed-apps", use: addAllowedAppWeb)  // ← changed
        }
    
    // MARK: - Login
    
    func showLogin(req: Request) async throws -> View {
        return try await req.view.render("login")
    }
    
    struct LoginFormData: Content {
        var username: String
        var password: String
    }
    
    func sessionLogin(req: Request) async throws -> Response {
        let form = try req.content.decode(LoginFormData.self)
        
        guard let user = try await User.query(on: req.db)
            .filter(\.$username == form.username)
            .first()
        else {
            return try await req.view.render("login", ["error": "Invalid username or password"]).encodeResponse(for: req)
        }
        
        guard try user.verify(password: form.password) else {
            return try await req.view.render("login", ["error": "Invalid username or password"]).encodeResponse(for: req)
        }
        
        req.auth.login(user)
        req.session.authenticate(user)
        return req.redirect(to: "/dashboard")
    }
    
    // MARK: - Dashboard
    
    func dashboard(req: Request) async throws -> View {
        let user = try req.auth.require(User.self)
        
        let children = try await ChildProfile.query(on: req.db)
            .filter(\.$parent.$id == user.requireID())
            .all()
        
        return try await req.view.render("dashboard", ["children": children])
    }
    
    // MARK: - Create Child
    
    struct CreateChildFormData: Content {
        var name: String
    }
    
    func createChild(req: Request) async throws -> Response {
        let user = try req.auth.require(User.self)
        let form = try req.content.decode(CreateChildFormData.self)
        
        let apiKey = [UInt8].random(count: 32).base64
        let child = ChildProfile(name: form.name, apiKey: apiKey, userID: try user.requireID())
        try await child.save(on: req.db)
        
        return req.redirect(to: "/dashboard")
    }
    
    // MARK: - Show One Child
    
    struct ChildPageContext: Encodable {
        var child: ChildProfile
        var apps: [AllowedApp]
    }
    
    func showChild(req: Request) async throws -> View {
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
    
    // MARK: - Add Allowed App
    
    struct AddAppFormData: Content {
        var appIdentifier: String
        var dailyLimitSeconds: Int?
    }
    
    func addAllowedAppWeb(req: Request) async throws -> Response {
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
