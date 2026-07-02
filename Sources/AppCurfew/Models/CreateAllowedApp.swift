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
            .field("daily_limit_seconds", .int)
            .field("remaining_seconds", .int)
            .field("last_checked_at", .datetime)
            .unique(on: "child_profile_id", "app_identifier")
            .field("allowed_days", .array(of: .string))
            .field("available_from", .string)
            .field("available_until", .string)
            .field("bypass_active", .bool, .required, .sql(.default(false)))
            .create()
    }
    
    func revert(on database: any Database) async throws { // to revert the database
        try await database.schema("allowed_apps").delete()
    }
}
