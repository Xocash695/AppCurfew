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

        let settings = try await ServerSettings.query(on: req.db).first()
        if settings?.registrationEnabled == false {
            throw Abort(.forbidden, reason: "Registration is currently disabled")
        }

        // The very first registered user becomes the admin.
        let userCount = try await User.query(on: req.db).count()
        let isAdmin = userCount == 0

        let user = User(
            name: create.name, username: create.username,
            passwordHash: try Bcrypt.hash(create.password),
            isAdmin: isAdmin
        )
            
        do {
            try await user.save(on: req.db)
        } catch {
                throw Abort(.conflict, reason: "Username already taken")
        }
            
        return user.asPublic()
    }
}
