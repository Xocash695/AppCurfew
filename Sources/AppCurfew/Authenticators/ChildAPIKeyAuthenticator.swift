//
//  ChildAuthenticator.swift
//  AppCurfew
//
//  Created by Akash Kallumkal on 2026-06-23.
//

import Vapor
import Fluent

struct ChildAPIKeyAuthenticator: AsyncBearerAuthenticator {
    func authenticate(bearer: BearerAuthorization, for request: Request) async throws {
        guard let child = try await ChildProfile.query(on: request.db)
            .filter(\.$apiKey == bearer.token)
            .first()
        else {
            return
        }
        request.auth.login(child)  // authenticate the child
    }
}
