//
//  UserToken.swift
//  AppCurfew
//
//  Created by Akash Kallumkal on 2026-06-19.
//

import Vapor

import Fluent // database stuff 


final class UserToken: Model, Content,  @unchecked Sendable {
    static let schema = "user_tokens"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "value")
    var value: String
    
    @Parent(key: "user_id") // modeling a belongs to relationship
    var user: User
    
    @Field(key: "expires_at")
    var expiresAt: Date
    
    init() {}
    
    init(id: UUID? = nil, value: String, userID: User.IDValue, expiresAt: Date) {
        self.id = id
        self.value = value
        self.$user.id = userID
        self.expiresAt = expiresAt
    }
}

extension UserToken: ModelTokenAuthenticatable {
    
    static var valueKey: KeyPath<UserToken, Field<String>> { \.$value }
    static var userKey: KeyPath<UserToken, Parent<User>> { \.$user }
   
    var isValid: Bool {
           expiresAt > Date()
       }
}
