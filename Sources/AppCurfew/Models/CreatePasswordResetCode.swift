//
//  CreatePasswordResetCode.swift
//  AppCurfew
//

import Fluent

struct CreatePasswordResetCode: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("password_reset_codes")
            .id()
            .field("code", .string, .required)
            .field("expires_at", .datetime, .required)
            .field("user_id", .uuid, .required, .references("users", "id"))
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema("password_reset_codes").delete()
    }
}
