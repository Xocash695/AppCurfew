//
//  ChildProfileController.swift
//  AppCurfew
//
//  Created by Akash Kallumkal on 2026-06-22.
//
import Vapor
import Fluent

struct ChildProfileController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let protected = routes.grouped(UserToken.authenticator())
        protected.post("children", use: create)
        protected.post("children", ":childID", "allowed-apps", use: addAllowedApp)
    }
    
    func create(req: Request) async throws -> ChildProfile {
        let user = try req.auth.require(User.self)
        
        struct CreateChildRequest: Content {
            var name: String
        }
        let input = try req.content.decode(CreateChildRequest.self)
        
        let apiKey = [UInt8].random(count: 32).base64
        let child = ChildProfile(name: input.name, apiKey: apiKey, userID: try user.requireID())
        
        try await child.save(on: req.db)
        return child
    }
    
    func addAllowedApp(req: Request) async throws -> AllowedApp {
        let user = try req.auth.require(User.self) // get the the parent logged in
        
        guard let childID = req.parameters.get("childID", as: UUID.self) else { // get the child id
            throw Abort(.badRequest)
        }
        
        guard let child = try await ChildProfile.find(childID, on: req.db) else {  // fetch the child from the database
            throw Abort(.notFound)
        }
         
        guard try child.$parent.id == user.requireID() else { // check if the child belongs to the parent
            throw Abort(.forbidden)
        }
        
        struct AddAppRequest: Content { // to decode what the parent sent
            var appIdentifier: String
        }
        let input = try req.content.decode(AddAppRequest.self)
        
        let app = AllowedApp(appIdentifier: input.appIdentifier, childProfileID: try child.requireID())
        try await app.save(on: req.db) // save the allowed app
        
        return app
    }
}

extension ChildProfile: Authenticatable {}
