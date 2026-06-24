//
//  CreateAllowedApp.swift
//  AppCurfew
//
//  Created by Akash Kallumkal on 2026-06-23.
//

import Fluent


struct CreateAllowedApp: AsyncMigration {
    func prepare(on database: any Database) async throws { // the way to create a database
        try await database.schema("allowed_apps")
            .id()
            .field("app_identifier", .string, .required)
            .field("child_profile_id", .uuid, .required, .references("child_profiles", "id"))
            .unique(on: "child_profile_id", "app_identifier") // preventing duplicate apps being listed 
            .create()
    }
    
    func revert(on database: any Database) async throws { // to revert the database
        try await database.schema("allowed_apps").delete()
    }
}
