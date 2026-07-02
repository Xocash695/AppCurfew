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
    
    @Field(key: "daily_limit_seconds")
    var dailyLimitSeconds: Int?      // the FULL allowance, e.g. 1800 for 30 min — never changes

    @Field(key: "remaining_seconds")
    var remainingSeconds: Int?       // counts down throughout the day

    @Field(key: "last_checked_at")
    var lastCheckedAt: Date?         // used both for elapsed-time calculation AND detecting a new day
    
    @Field(key: "allowed_days")
    var allowedDays: [Weekday]?
    
    @Field(key: "available_from")      // ← add here
    var availableFrom: String?
      
    @Field(key: "available_until")     // ← add here
    var availableUntil: String?

    @Field(key: "bypass_active")
    var bypassActive: Bool

    init() {}
    
    init(
        id: UUID? = nil,
        appIdentifier: String,
        childProfileID: IDValue,
        dailyLimitSeconds: Int? = nil,
        allowedDays: [Weekday]? = nil,
        availableFrom: String? = nil,
        availableUntil: String? = nil,
        bypassActive: Bool = false
    ) {
        self.id = id
        self.appIdentifier = appIdentifier
        self.$childProfile.id = childProfileID
        self.dailyLimitSeconds = dailyLimitSeconds
        self.remainingSeconds = dailyLimitSeconds
        self.lastCheckedAt = nil
        self.allowedDays = allowedDays
        self.availableFrom = availableFrom
        self.availableUntil = availableUntil
        self.bypassActive = bypassActive
    }
}
