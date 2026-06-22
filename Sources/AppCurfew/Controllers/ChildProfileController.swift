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
}
