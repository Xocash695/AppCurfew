import Vapor
import Fluent

// the endpoint that the child's device will connect to

struct AllowedAppController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let childProtected = routes.grouped(ChildAPIKeyAuthenticator())
        childProtected.get("allowed-apps", use: list)
        childProtected.post("usage-report", use: reportUsage)
    }
    
    func list(req: Request) async throws -> [String] {
        let child = try req.auth.require(ChildProfile.self)
        
        let apps = try await AllowedApp.query(on: req.db)
            .filter(\.$childProfile.$id == child.requireID())
            .all()
        
        var allowedNames: [String] = []
        let now = Date()
        let todayWeekdayNumber = Calendar.current.component(.weekday, from: now)
        
        for app in apps {
            // NEW: day-of-week gate, checked FIRST
            if let allowedDays = app.allowedDays {
                let isTodayAllowed = allowedDays.contains { $0.calendarValue == todayWeekdayNumber }
                guard isTodayAllowed else {
                    continue  // skip this app entirely, wrong day
                }
            }
            
            // existing time-limit logic continues below, unchanged
            guard app.dailyLimitSeconds != nil else {
                allowedNames.append(app.appIdentifier)
                continue
            }
            
            if let lastChecked = app.lastCheckedAt, Calendar.current.isDate(lastChecked, inSameDayAs: now) {
                if let remaining = app.remainingSeconds, remaining > 0 {
                    allowedNames.append(app.appIdentifier)
                }
            } else {
                app.remainingSeconds = app.dailyLimitSeconds
                app.lastCheckedAt = now
                try await app.save(on: req.db)
                allowedNames.append(app.appIdentifier)
            }
        }
        
        return allowedNames
    }
    
    struct UsageReportRequest: Content {
        var appIdentifier: String
        var secondsUsed: Int
    }
    
    struct UsageReportResponse: Content {
        var remainingSeconds: Int?
    }
    
    func reportUsage(req: Request) async throws -> UsageReportResponse {
        let child = try req.auth.require(ChildProfile.self)
        let input = try req.content.decode(UsageReportRequest.self)
        
        guard let app = try await AllowedApp.query(on: req.db)
            .filter(\.$childProfile.$id == child.requireID())
            .filter(\.$appIdentifier == input.appIdentifier)
            .first()
        else {
            throw Abort(.notFound)
        }
        
        let now = Date()
        
        if let lastChecked = app.lastCheckedAt, Calendar.current.isDate(lastChecked, inSameDayAs: now) {
            // same day — subtract reported usage
            app.remainingSeconds = (app.remainingSeconds ?? 0) - input.secondsUsed
        } else {
            // new day — reset first, then subtract this usage
            app.remainingSeconds = (app.dailyLimitSeconds ?? 0) - input.secondsUsed
        }
        
        app.lastCheckedAt = now
        try await app.save(on: req.db)
        
        return UsageReportResponse(remainingSeconds: app.remainingSeconds)
    }
}
