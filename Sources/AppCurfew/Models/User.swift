//
//  User.swift
//  AppCurfew
//
//  Created by Akash Kallumkal on 2026-06-18.
//

import Vapor

import Fluent


final class User: Model, Content, @unchecked Sendable  {
 
    
    static let schema = "users" // tells fluent what the database is called

    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "name")
    var name: String
    
    @Field(key: "username")
    var username: String
    
    @Field(key: "password_hash")
    var passwordHash: String

    @Field(key: "is_admin")
    var isAdmin: Bool

    init(){}

    init(id: UUID? = nil, name: String, username: String, passwordHash: String, isAdmin: Bool = false) {
        self.id = id
        self.name = name
        self.username = username
        self.passwordHash = passwordHash
        self.isAdmin = isAdmin
    }
    
}


extension User {
    struct Create: Content {
        var name: String
        var username: String
        var password: String
        var confirmPassword: String
    }
}

extension User.Create: Validatable {
    static func validations(_ validations: inout Validations) {
        validations.add("name", as: String.self, is: !.empty)  // ← add here
        validations.add("username", as: String.self, is: !.empty)
        validations.add("password", as: String.self, is: .count(8...))
    }
}

extension User: ModelAuthenticatable {
    static var usernameKey: KeyPath<User, Field<String>> { \.$username }
    static var passwordHashKey: KeyPath<User, Field<String>> { \.$passwordHash }
    func verify(password: String) throws -> Bool {
        try Bcrypt.verify(password, created: self.passwordHash)
    }
}

extension User {
    struct Public: Content { // for public facing stuff cause we don't want to give back like the password hash
        var id: UUID?
        var name: String
        var username: String
        // notice: NO passwordHash
    }
    func asPublic() -> User.Public {
        User.Public(id: self.id, name: self.name, username: self.username)
    }
}


extension User: SessionAuthenticatable { // making the user session authenticatable
    var sessionID: String {
        self.id!.uuidString
    }
}
