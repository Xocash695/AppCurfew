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
    
    
    @Field(key: "name") // fluent storing the name
    var name: String
    
    @Field(key: "username")
    var username: String
    
    @Field(key: "password_hash")
    var passwordHash: String
    
    init(){}
    
    init(id: UUID? = nil, name: String, username: String, passwordHash: String) {
        self.id = id
        self.name = name
        self.username = username
        self.passwordHash = passwordHash
    }
    
}


extension User {
    struct Create: Content {
        var username: String
        var password: String
        var confirmPassword: String
    }
}

extension User.Create: Validatable {
    static func validations(_ validations: inout Validations) {
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
