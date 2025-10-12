//
//  PrayerResponse.swift
//  Noorani
//
//  Created by Amin Pourgol on 10/4/25.
//  Copyright © 2025 AP Bros. All rights reserved.
//


struct PrayerResponse: Codable {
    let data: PrayerData
}

struct CalendarPrayerResponse: Codable {
    let data: [PrayerData]
}

struct PrayerData: Codable {
    let timings: [String: String]
    let date: PrayerDate
}

struct PrayerDate: Codable {
    let readable: String
    let hijri: HijriDate
    let gregorian: GregorianDate
}

struct HijriDate: Codable {
    let date: String
    let weekday: Weekday
    let month: HijriMonth
    let year: String
}

struct GregorianDate: Codable {
    let date: String
    let weekday: Weekday
    let month: GregorianMonth
    let year: String
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
}
