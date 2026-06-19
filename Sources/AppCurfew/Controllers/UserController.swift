//
//  UserController.swift
//  AppCurfew
//
//  Created by Akash Kallumkal on 2026-06-18.
//

import Vapor
import Fluent

struct UserController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        routes.post("register", use: register)
    }
    func register(req: Request) async throws -> User.Public {
        let create = try req.content.decode(User.Create.self)
            
        guard create.password == create.confirmPassword else {
                throw Abort(.badRequest, reason: "Passwords did not match")
        }
            
        let user = User(
            name: create.name, username: create.username,
            passwordHash: try Bcrypt.hash(create.password)
        )
            
        do {
            try await user.save(on: req.db)
        } catch {
                throw Abort(.conflict, reason: "Username already taken")
        }
            
        return user.asPublic()
    }
}
