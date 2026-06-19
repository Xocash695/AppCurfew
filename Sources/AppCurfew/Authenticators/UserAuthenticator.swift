import Vapor
import Fluent

struct UserAuthenticator: AsyncBasicAuthenticator {
    func authenticate(
        basic: BasicAuthorization,
        for request: Request
    ) async throws {
        guard let user = try await User.query(on: request.db)
            .filter(\.$username == basic.username)
            .first()
        else {
            return
        }
        
        if try user.verify(password: basic.password) {
            request.auth.login(user)
        }
    }
}
