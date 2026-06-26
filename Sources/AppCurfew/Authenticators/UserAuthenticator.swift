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

struct UserSessionAuthenticator: AsyncSessionAuthenticator {
    typealias User = AppCurfew.User
    
    func authenticate(sessionID: String, for request: Request) async throws {
        print("Authenticating with sessionID: \(sessionID)")
        
        guard let userID = UUID(uuidString: sessionID) else {
            print("Could not parse sessionID as UUID!")
            return
        }
        
        guard let user = try await AppCurfew.User.find(userID, on: request.db) else {
            print("No user found with ID: \(userID)")
            return
        }
        
        request.auth.login(user)
 
    }
}
