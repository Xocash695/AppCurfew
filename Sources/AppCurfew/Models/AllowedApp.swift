//
//  AllowedApp.swift
//  AppCurfew
//
//  Created by Akash Kallumkal on 2026-06-22.
//

import Vapor
import Fluent

final class AllowedApp: Model, Content, @unchecked Sendable {
    static let schema = "allowed_apps"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "app_identifier") // the string of the app identifer
    var appIdentifier: String
    
    @Parent(key: "child_profile_id")
    var childProfile: ChildProfile
    
    init() {}
    
    init(id: UUID? = nil, appIdentifier: String, childProfileID: ChildProfile.IDValue) {
        self.id = id
        self.appIdentifier = appIdentifier
        self.$childProfile.id = childProfileID
    }
}
