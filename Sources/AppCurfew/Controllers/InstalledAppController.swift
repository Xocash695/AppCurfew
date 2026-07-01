//
//  InstalledAppController.swift
//  AppCurfew
//
//  Created by Akash Kallumkal on 2026-07-01.
//

import Vapor
import Fluent

struct InstalledAppController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let childProtected = routes.grouped(ChildAPIKeyAuthenticator())
        childProtected.post("installed-apps", use: reportInstalledApps)
    }
    
    struct InstalledAppReport: Content {
        var id: String
        var name: String
    }
    
    struct InstalledAppsRequest: Content {
        var apps: [InstalledAppReport]
    }
    
    func reportInstalledApps(req: Request) async throws -> HTTPStatus {
        let child = try req.auth.require(ChildProfile.self)
        let input = try req.content.decode(InstalledAppsRequest.self)
        
        // Step 1: wipe existing rows for this child
        try await InstalledApp.query(on: req.db)
            .filter(\.$childProfile.$id == child.requireID())
            .delete()
        
        // Step 2: insert the fresh list
        for app in input.apps {
            let installedApp = InstalledApp(
                appIdentifier: app.id,
                displayName: app.name,
                childProfileID: try child.requireID()
            )
            try await installedApp.save(on: req.db)
        }
        
        return .ok
    }
}
