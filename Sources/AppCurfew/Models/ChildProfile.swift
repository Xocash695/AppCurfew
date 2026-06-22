//
//  ChildProfile.swift
//  AppCurfew
//
//  Created by Akash Kallumkal on 2026-06-21.
//

// the child's profile basically


import Vapor
import Fluent


final class ChildProfile: Model, Content, @unchecked Sendable {
    
    static let schema = "child_profiles"
    
    @ID(key: .id) var id: UUID?
    
    @Field(key: "name") var name: String
    
    @Field(key: "api_key") var apiKey: String
    
    @Parent(key: "user_id") var parent: User
    
    init() {}
    
    init(id:UUID? = nil, name:String, apiKey:String, userID: User.IDValue ) {
        self.id  = id
        self.apiKey = apiKey
        self.name = name
        self.$parent.id = userID
    }
    
    
}
