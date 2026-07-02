//
//  CreateUser.swift
//  AppCurfew
//
//  Created by Akash Kallumkal on 2026-06-18.
//

import Fluent

struct CreateUser: AsyncMigration { // to create the user database in the database
    func prepare(on database: any Database) async throws {
            // Make a change to the database.
        
        try await database.schema("users")
            .id()
            .field("name", .string, .required)
            .field("username", .string, .required)
            .unique(on: "username")  // ← prevents duplicates for usernames
            .field("password_hash", .string, .required)
            .field("is_admin", .bool, .required, .sql(.default(false)))
            .create()
        

        }
     
    func revert(on database: any Database) async throws {
            // Undo the change made in `prepare`, if possible.
        try await database.schema("users").delete() // delete the table
    }

    
    
}
