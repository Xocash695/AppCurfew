//
//  ServerSettings.swift
//  AppCurfew
//

import Vapor
import Fluent

final class ServerSettings: Model, Content, @unchecked Sendable {
    static let schema = "server_settings"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "registration_enabled")
    var registrationEnabled: Bool

    init() {}

    init(id: UUID? = nil, registrationEnabled: Bool = true) {
        self.id = id
        self.registrationEnabled = registrationEnabled
    }
}

struct CreateServerSettings: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("server_settings")
            .id()
            .field("registration_enabled", .bool, .required)
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema("server_settings").delete()
    }
}

struct SeedServerSettings: AsyncMigration {
    func prepare(on database: any Database) async throws {
        // Only seed if no settings row exists yet.
        let existing = try await ServerSettings.query(on: database).first()
        if existing == nil {
            let settings = ServerSettings(registrationEnabled: true)
            try await settings.save(on: database)
        }
    }

    func revert(on database: any Database) async throws {
        try await ServerSettings.query(on: database).delete()
    }
}
