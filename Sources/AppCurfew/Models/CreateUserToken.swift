//
//  CreateUserToken.swift
//  AppCurfew
//
//  Created by Akash Kallumkal on 2026-06-19.
//
import Fluent

struct CreateUserToken: AsyncMigration {
    
    func prepare(on database: any Database) async throws {
        try await database.schema("user_tokens")
            .id()
            .field("value", .string, .required)
            .field("user_id", .uuid, .required, .references("users", "id"))
            .unique(on: "value")
            .create()
    }
    
    func revert(on database: any Database) async throws {
        try await database.schema("user_tokens").delete()
    }
}
