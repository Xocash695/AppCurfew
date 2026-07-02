//
//  WebController.swift
//  AppCurfew
//
//  Created by Akash Kallumkal on 2026-06-26.
//

import Vapor
import Fluent
import Leaf

struct WebController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
            routes.get("", use: landing)
            routes.get("login", use: showLogin)
            routes.post("session-login", use: sessionLogin)
            routes.get("register", use: showRegister)
            routes.post("web-register", use: webRegister)
            routes.post("logout", use: logout)
            routes.get("dashboard", use: dashboard)
            routes.post("dashboard", "children", use: createChild)
            routes.post("dashboard", "toggle-registration", use: toggleRegistration)
            routes.get("children", ":childID", use: showChild)
            routes.post("dashboard", "children", ":childID", "allowed-apps", use: addAllowedAppWeb)  // ← changed
            routes.post("dashboard", "children", ":childID", "allowed-apps", ":appID", "delete", use: deleteAllowedApp)
            routes.post("dashboard", "children", ":childID", "allowed-apps", ":appID", "edit", use: editAllowedApp)
            routes.post("dashboard", "children", ":childID", "delete", use: deleteChild)
            routes.post("dashboard", "children", ":childID", "allowed-apps", ":appID", "bypass", use: startBypass)
            routes.post("dashboard", "children", ":childID", "allowed-apps", ":appID", "unbypass", use: endBypass)
        }
    
    // MARK: - Landing

    func landing(req: Request) async throws -> Response {
        // The global session authenticator has already populated req.auth if a
        // valid session exists — send signed-in users straight to their dashboard.
        if req.auth.has(User.self) {
            return req.redirect(to: "/dashboard")
        }
        return try await req.view.render("landing").encodeResponse(for: req)
    }

    // MARK: - Login

    func showLogin(req: Request) async throws -> View {
        return try await req.view.render("login")
    }
    
    struct LoginFormData: Content {
        var username: String
        var password: String
    }
    
    func sessionLogin(req: Request) async throws -> Response {
        let form = try req.content.decode(LoginFormData.self)
        
        guard let user = try await User.query(on: req.db)
            .filter(\.$username == form.username)
            .first()
        else {
            return try await req.view.render("login", ["error": "Invalid username or password"]).encodeResponse(for: req)
        }
        
        guard try user.verify(password: form.password) else {
            return try await req.view.render("login", ["error": "Invalid username or password"]).encodeResponse(for: req)
        }
        
        req.auth.login(user)
        req.session.authenticate(user)
        return req.redirect(to: "/dashboard")
    }

    // MARK: - Register

    func showRegister(req: Request) async throws -> View {
        return try await req.view.render("register")
    }

    struct RegisterFormData: Content {
        var name: String
        var username: String
        var password: String
        var confirmPassword: String
    }

    func webRegister(req: Request) async throws -> Response {
        let form = try req.content.decode(RegisterFormData.self)

        guard form.password == form.confirmPassword else {
            return try await req.view.render("register", ["error": "Passwords do not match"]).encodeResponse(for: req)
        }

        let settings = try await ServerSettings.query(on: req.db).first()
        if settings?.registrationEnabled == false {
            return try await req.view.render("register", ["error": "Registration is currently disabled"]).encodeResponse(for: req)
        }

        // The very first registered user becomes the admin.
        let userCount = try await User.query(on: req.db).count()
        let isAdmin = userCount == 0

        let user = User(
            name: form.name,
            username: form.username,
            passwordHash: try Bcrypt.hash(form.password),
            isAdmin: isAdmin
        )

        do {
            try await user.save(on: req.db)
        } catch {
            return try await req.view.render("register", ["error": "Username already taken"]).encodeResponse(for: req)
        }

        req.auth.login(user)
        req.session.authenticate(user)
        return req.redirect(to: "/dashboard")
    }
    
    // MARK: - Logout

    func logout(req: Request) async throws -> Response {
        req.session.unauthenticate(User.self)
        req.session.destroy()
        req.auth.logout(User.self)
        return req.redirect(to: "/login")
    }

    // MARK: - Dashboard

    struct DashboardContext: Encodable {
        var children: [ChildProfile]
        var isAdmin: Bool
        var registrationEnabled: Bool
    }

    func dashboard(req: Request) async throws -> View {
        let user = try req.auth.require(User.self)

        let children = try await ChildProfile.query(on: req.db)
            .filter(\.$parent.$id == user.requireID())
            .all()

        let settings = try await ServerSettings.query(on: req.db).first()

        return try await req.view.render("dashboard", DashboardContext(
            children: children,
            isAdmin: user.isAdmin,
            registrationEnabled: settings?.registrationEnabled ?? true
        ))
    }

    func toggleRegistration(req: Request) async throws -> Response {
        let user = try req.auth.require(User.self)
        guard user.isAdmin else {
            throw Abort(.forbidden)
        }

        guard let settings = try await ServerSettings.query(on: req.db).first() else {
            throw Abort(.internalServerError, reason: "Server settings not found")
        }

        settings.registrationEnabled.toggle()
        try await settings.save(on: req.db)

        return req.redirect(to: "/dashboard")
    }
    
    // MARK: - Create Child
    
    struct CreateChildFormData: Content {
        var name: String
    }
    
    func createChild(req: Request) async throws -> Response {
        let user = try req.auth.require(User.self)
        let form = try req.content.decode(CreateChildFormData.self)
        
        let apiKey = [UInt8].random(count: 32).base64
        let child = ChildProfile(name: form.name, apiKey: apiKey, userID: try user.requireID())
        try await child.save(on: req.db)
        
        return req.redirect(to: "/dashboard")
    }
    
    // MARK: - Show One Child

    struct ChildPageContext: Encodable {
        var child: ChildProfile
        var apps: [AppDisplay]          // ← changed from [AllowedApp]
        var installedApps: [InstalledApp]
        var editingApp: EditContext?    // non-nil when ?edit=<appID> targets an owned app
    }

    // Pre-computed, template-friendly values for pre-filling the add/edit form.
    struct EditContext: Encodable {
        var id: UUID?
        var appIdentifier: String
        var hoursValue: String
        var minutesValue: String
        var availableFrom: String
        var availableUntil: String
        var monday: Bool
        var tuesday: Bool
        var wednesday: Bool
        var thursday: Bool
        var friday: Bool
        var saturday: Bool
        var sunday: Bool
    }

    func showChild(req: Request) async throws -> View {
        let user = try req.auth.require(User.self)
        
        guard let childID = req.parameters.get("childID", as: UUID.self),
              let child = try await ChildProfile.find(childID, on: req.db),
              try child.$parent.id == user.requireID()
        else {
            throw Abort(.notFound)
        }
        
        let apps = try await AllowedApp.query(on: req.db)
            .filter(\.$childProfile.$id == child.requireID())
            .all()
        
        let displayApps = apps.map { app in
            AppDisplay(
                id: app.id,
                appIdentifier: app.appIdentifier,
                remainingFormatted: app.remainingSeconds.map { formatDuration($0) },
                limitFormatted: app.dailyLimitSeconds.map { formatDuration($0) },
                allowedDays: app.allowedDays,
                availableFrom: app.availableFrom,
                availableUntil: app.availableUntil,
                bypassActive: app.bypassActive
            )
        }
        
        let installedApps = try await InstalledApp.query(on: req.db)
            .filter(\.$childProfile.$id == child.requireID())
            .all()

        // If ?edit=<appID> targets one of this child's apps, build a pre-fill context.
        var editingApp: EditContext? = nil
        if let editID = req.query[UUID.self, at: "edit"],
           let app = apps.first(where: { $0.id == editID }) {
            let hours = app.dailyLimitSeconds.map { $0 / 3600 }
            let minutes = app.dailyLimitSeconds.map { ($0 % 3600) / 60 }
            let days = Set(app.allowedDays ?? [])
            editingApp = EditContext(
                id: app.id,
                appIdentifier: app.appIdentifier,
                hoursValue: hours.map(String.init) ?? "",
                minutesValue: minutes.map(String.init) ?? "",
                availableFrom: app.availableFrom ?? "",
                availableUntil: app.availableUntil ?? "",
                monday: days.contains(.monday),
                tuesday: days.contains(.tuesday),
                wednesday: days.contains(.wednesday),
                thursday: days.contains(.thursday),
                friday: days.contains(.friday),
                saturday: days.contains(.saturday),
                sunday: days.contains(.sunday)
            )
        }

        return try await req.view.render("child", ChildPageContext(child: child, apps: displayApps, installedApps: installedApps, editingApp: editingApp))
    }

    
    // MARK: - Add Allowed App
    
    struct AddAppFormData: Content {
        var appIdentifier: String
        var limitHours: String?
        var limitMinutes: String?
        var allowedDays: [Weekday]?
        var availableFrom: String?
        var availableUntil: String?
    }

    func addAllowedAppWeb(req: Request) async throws -> Response {
        let user = try req.auth.require(User.self)
        
        guard let childID = req.parameters.get("childID", as: UUID.self),
              let child = try await ChildProfile.find(childID, on: req.db),
              try child.$parent.id == user.requireID()
        else {
            throw Abort(.notFound)
        }
        
        let form = try req.content.decode(AddAppFormData.self)
        
        // Convert amount + unit into seconds
        let hours = Int(form.limitHours ?? "") ?? 0
        let minutes = Int(form.limitMinutes ?? "") ?? 0
        let totalSeconds = hours * 3600 + minutes * 60
        let dailyLimitSeconds: Int? = totalSeconds > 0 ? totalSeconds : nil
        
        // Empty checkbox selection means "every day" → nil
        let days = (form.allowedDays?.isEmpty ?? true) ? nil : form.allowedDays

        // HTML time inputs submit "" when blank — treat as nil
        let availableFrom = form.availableFrom?.isEmpty == true ? nil : form.availableFrom
        let availableUntil = form.availableUntil?.isEmpty == true ? nil : form.availableUntil

        let app = AllowedApp(
            appIdentifier: form.appIdentifier,
            childProfileID: try child.requireID(),
            dailyLimitSeconds: dailyLimitSeconds,
            allowedDays: days,
            availableFrom: availableFrom,
            availableUntil: availableUntil
        )
        try await app.save(on: req.db)
        
        return req.redirect(to: "/children/\(childID)")
    }
    func deleteChild(req: Request) async throws -> Response {
        let user = try req.auth.require(User.self)

        guard let childID = req.parameters.get("childID", as: UUID.self),
              let child = try await ChildProfile.find(childID, on: req.db),
              try child.$parent.id == user.requireID()
        else {
            throw Abort(.notFound)
        }

        try await AllowedApp.query(on: req.db)
            .filter(\.$childProfile.$id == childID)
            .delete()

        try await InstalledApp.query(on: req.db)
            .filter(\.$childProfile.$id == childID)
            .delete()

        try await child.delete(on: req.db)

        return req.redirect(to: "/dashboard")
    }

    // Resolves the child + app from the route and verifies both belong to the authenticated user.
    private func findOwnedApp(req: Request) async throws -> (User, ChildProfile, AllowedApp) {
        let user = try req.auth.require(User.self)

        guard let childID = req.parameters.get("childID", as: UUID.self),
              let appID = req.parameters.get("appID", as: UUID.self),
              let child = try await ChildProfile.find(childID, on: req.db),
              try child.$parent.id == user.requireID(),
              let app = try await AllowedApp.find(appID, on: req.db),
              app.$childProfile.id == childID
        else {
            throw Abort(.notFound)
        }

        return (user, child, app)
    }

    func deleteAllowedApp(req: Request) async throws -> Response {
        let (_, child, app) = try await findOwnedApp(req: req)

        try await app.delete(on: req.db)
        return req.redirect(to: "/children/\(child.id!)")
    }

    func editAllowedApp(req: Request) async throws -> Response {
        let (_, child, app) = try await findOwnedApp(req: req)

        let form = try req.content.decode(AddAppFormData.self)

        // Convert amount + unit into seconds (same safe parsing as addAllowedAppWeb)
        let hours = Int(form.limitHours ?? "") ?? 0
        let minutes = Int(form.limitMinutes ?? "") ?? 0
        let totalSeconds = hours * 3600 + minutes * 60
        let dailyLimitSeconds: Int? = totalSeconds > 0 ? totalSeconds : nil

        // Empty checkbox selection means "every day" → nil
        let days = (form.allowedDays?.isEmpty ?? true) ? nil : form.allowedDays

        // HTML time inputs submit "" when blank — treat as nil
        let availableFrom = form.availableFrom?.isEmpty == true ? nil : form.availableFrom
        let availableUntil = form.availableUntil?.isEmpty == true ? nil : form.availableUntil

        // Update the existing row in place
        app.appIdentifier = form.appIdentifier
        app.dailyLimitSeconds = dailyLimitSeconds
        app.allowedDays = days
        app.availableFrom = availableFrom
        app.availableUntil = availableUntil
        try await app.save(on: req.db)

        return req.redirect(to: "/children/\(child.id!)")
    }

    func startBypass(req: Request) async throws -> Response {
        let (_, child, app) = try await findOwnedApp(req: req)

        app.bypassActive = true
        try await app.save(on: req.db)
        return req.redirect(to: "/children/\(child.id!)")
    }

    func endBypass(req: Request) async throws -> Response {
        let (_, child, app) = try await findOwnedApp(req: req)

        app.bypassActive = false
        try await app.save(on: req.db)
        return req.redirect(to: "/children/\(child.id!)")
    }
    
    struct AppDisplay: Encodable {
        var id: UUID?
        var appIdentifier: String
        var remainingFormatted: String?
        var limitFormatted: String?
        var allowedDays: [Weekday]?
        var availableFrom: String?
        var availableUntil: String?
        var bypassActive: Bool
    }

    func formatDuration(_ seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = seconds % 60
        if h > 0 { return m > 0 ? "\(h)h \(m)m" : "\(h)h" }
        if m > 0 { return s > 0 ? "\(m)m \(s)s" : "\(m)m" }
        return "\(s)s"
    }
    
}
