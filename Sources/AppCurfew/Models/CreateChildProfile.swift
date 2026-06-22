//
//  CreateChildProfile.swift
//  AppCurfew
//
//  Created by Akash Kallumkal on 2026-06-21.
//

import Fluent

struct CreateChildProfile: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("child_profiles")
            .id()
            .field("name", .string, .required)
            .field("api_key", .string, .required)
            .field("user_id", .uuid, .required, .references("users", "id"))
            .unique(on: "api_key") // because we want each key to be unique
            .create()
    }
    
    func revert(on database: any Database) async throws { // if we have to revert stuff
        try await database.schema("child_profiles").delete()
    }
}
