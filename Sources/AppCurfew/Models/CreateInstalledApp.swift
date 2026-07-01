//
//  CreateInstalledApp.swift
//  AppCurfew
//
//  Created by Akash Kallumkal on 2026-07-01.
//

import Fluent

struct CreateInstalledApp: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("installed_apps")
            .id()
            .field("app_identifier", .string, .required)
            .field("display_name", .string, .required)
            .field("child_profile_id", .uuid, .required, .references("child_profiles", "id"))
            .create()
    }
    
    func revert(on database: any Database) async throws {
        try await database.schema("installed_apps").delete()
    }
}
