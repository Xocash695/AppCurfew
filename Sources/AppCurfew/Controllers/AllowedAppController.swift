//
//  AllowedAppController.swift
//  AppCurfew
//
//  Created by Akash Kallumkal on 2026-06-23.
//

import Vapor
import Fluent

struct AllowedAppController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let childProtected = routes.grouped(ChildAPIKeyAuthenticator())
        childProtected.get("allowed-apps", use: list)
    }
    
    func list(req: Request) async throws -> [String] {
        let child = try req.auth.require(ChildProfile.self)
        
        let apps = try await AllowedApp.query(on: req.db)
            .filter(\.$childProfile.$id == child.requireID())
            .all()
        
        return apps.map { $0.appIdentifier } // gives an array of strings
    }
}
