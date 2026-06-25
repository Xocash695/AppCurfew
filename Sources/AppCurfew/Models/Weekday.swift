//
//  File.swift
//  AppCurfew
//
//  Created by Akash Kallumkal on 2026-06-24.
//

enum Weekday: String, Codable, CaseIterable {
    case sunday, monday, tuesday, wednesday, thursday, friday, saturday
}

extension Weekday {
    var calendarValue: Int {
        switch self {
        case .sunday: return 1
        case .monday: return 2
        case .tuesday: return 3
        case .wednesday: return 4
        case .thursday: return 5
        case .friday: return 6
        case .saturday: return 7
        }
    }
}
