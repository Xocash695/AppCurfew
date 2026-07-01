//
//  InstalledApp.swift
//  AppCurfew
//
//  Created by Akash Kallumkal on 2026-07-01.
//

import Vapor
import Fluent

final class InstalledApp: Model, Content, @unchecked Sendable {
    static let schema = "installed_apps"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "app_identifier")
    var appIdentifier: String
    
    @Field(key: "display_name")
    var displayName: String
    
    @Parent(key: "child_profile_id")
    var childProfile: ChildProfile
    
    init() {}
    
    init(id: UUID? = nil, appIdentifier: String, displayName: String, childProfileID: ChildProfile.IDValue) {
        self.id = id
        self.appIdentifier = appIdentifier
        self.displayName = displayName
        self.$childProfile.id = childProfileID
    }
}
