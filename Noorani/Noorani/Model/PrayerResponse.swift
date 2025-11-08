//
//  PrayerResponse.swift
//  Noorani
//  Copyright © 2025 AP Bros. All rights reserved.
//

// MARK: - Prayer Times API Response Models
struct PrayerResponse: Codable {
    let code: Int
    let status: String
    let data: PrayerData
}

struct CalendarPrayerResponse: Codable {
    let code: Int
    let status: String
    let data: [PrayerData]
}

struct PrayerData: Codable {
    let timings: [String: String]
    let date: PrayerDate
}

struct PrayerDate: Codable {
    let readable: String
    let timestamp: String
    let gregorian: GregorianDate
    let hijri: HijriDate
}

struct HijriDate: Codable {
    let date: String
    let format: String
    let day: String
    let weekday: Weekday
    let month: HijriMonth
    let year: String
    let designation: Designation
    let holidays: [String]
}

struct GregorianDate: Codable {
    let date: String
    let format: String
    let day: String
    let weekday: Weekday
    let month: GregorianMonth
    let year: String
    let designation: Designation
}

struct Weekday: Codable {
    let en: String
    let ar: String?
}

struct HijriMonth: Codable {
    let number: Int
    let en: String
    let ar: String
}

struct GregorianMonth: Codable {
    let number: Int
    let en: String
    let ar: String?
}

struct Designation: Codable {
    let abbreviated: String
    let expanded: String
}
