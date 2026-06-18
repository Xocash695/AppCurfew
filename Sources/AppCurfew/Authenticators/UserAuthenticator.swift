import Vapor

struct UserAuthenticator: AsyncBasicAuthenticator {
    nonisolated(unsafe) static var storedPasswordHash: String = ""

    func authenticate(
        basic: BasicAuthorization,
        for request: Request
    ) async throws {
        guard basic.username == "test" else { return }
        if try await request.password.async.verify(basic.password, created: Self.storedPasswordHash) {
            request.auth.login(User(name: "Vapor"))
        }
    }
}
