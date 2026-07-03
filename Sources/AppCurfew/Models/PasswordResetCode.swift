//
//  PasswordResetCode.swift
//  AppCurfew
//

import Vapor
import Fluent

final class PasswordResetCode: Model, Content, @unchecked Sendable {
    static let schema = "password_reset_codes"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "code")
    var code: String

    @Field(key: "expires_at")
    var expiresAt: Date

    @Parent(key: "user_id")
    var user: User

    init() {}

    init(id: UUID? = nil, code: String, expiresAt: Date, userID: User.IDValue) {
        self.id = id
        self.code = code
        self.expiresAt = expiresAt
        self.$user.id = userID
    }
}
