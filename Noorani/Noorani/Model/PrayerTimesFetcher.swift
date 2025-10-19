//
//  PrayerTimesFetcher.swift
//  Noorani
//
//  Created by Amin Pourgol on 10/4/25.
//  Copyright © 2025 AP Bros. All rights reserved.
//

import Foundation
import SwiftUI

class PrayerTimesFetcher: ObservableObject {
    @Published var timings: [String: String] = [:]
    @Published var readableDate: String = ""
    @Published var hijriDate: String = ""
    @Published var prayerTimes: [String: Date] = [:] // All prayer times for today and tomorrow
    @Published var nextPrayerName: String = ""
    @Published var nextPrayerTime: Date?
    @Published var countdown: String = ""
    
    @AppStorage("currentLat") var currentLat: Double = 0.0
    @AppStorage("currentLng") var currentLng: Double = 0.0

    private var timer: Timer?

    func updateNextPrayer() {
        let now = Date()
        
        // Get all upcoming prayer times (both today and tomorrow) sorted by time
        let upcomingPrayers = prayerTimes
            .filter { $0.value > now }
            .sorted { $0.value < $1.value }

        if let next = upcomingPrayers.first {
            // Clean up the prayer name (remove "Tomorrow_" prefix if present)
            let cleanName = next.key.hasPrefix("Tomorrow_") ? 
                String(next.key.dropFirst("Tomorrow_".count)) : next.key
            
            nextPrayerName = cleanName
            nextPrayerTime = next.value
            startCountdown(to: next.value)
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yyyy"
        return formatter.string(from: date)
    }


    
    private var allowedPrayerKeys: Set<String> {
        // TODO: Customize this based on sect. Maybe make it configurable in settings?
        return ["Fajr", "Sunrise", "Dhuhr", "Sunset", "Maghrib", "Midnight"] // Shia
        // return ["Fajr", "Dhuhr", "Asr", "Maghrib", "Isha"] // Sunni
    }


    private func startCountdown(to date: Date) {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            let interval = date.timeIntervalSince(Date())
            if interval <= 0 {
                self?.countdown = "Now"
                self?.timer?.invalidate()
            } else {
                self?.countdown = self?.format(interval) ?? ""
            }
        }
    }

    private func format(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    func fetchPrayerTimes(latitude: Double, longitude: Double) {
        // Calculate tomorrow's date for the end date
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yyyy"
        guard let endDate = Calendar.current.date(byAdding: .day, value: 2, to: Date()) else {
            return
        }
        
        let startDateString = formatter.string(from: Date())
        let endDateString = formatter.string(from: endDate)
        
        print("Start date: \(startDateString) & End date: \(endDateString)")
        
        // Use calendar API to get two days worth of prayer times
        let urlString = "https://api.aladhan.com/v1/calendar/from/\(startDateString)/to/\(endDateString)?latitude=\(latitude)&longitude=\(longitude)&method=7&iso8601=true&midnightMode=1"
        guard let url = URL(string: urlString) else { return }

        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil else { 
                print("Network error: \(error?.localizedDescription ?? "Unknown error")")
                return 
            }

            do {
                // Debug: Print the raw response to see what we're getting
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("API Response: \(jsonString)")
                }
                
                let response = try JSONDecoder().decode(CalendarPrayerResponse.self, from: data)
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"

                DispatchQueue.main.async {
                    // Clear previous prayer times
                    self.prayerTimes = [:]
                    let now = Date()
                    let calendar = Calendar.current
                    let today = calendar.startOfDay(for: now)
                    
                    // Create date formatter for API's gregorian date format
                    let apiDateFormatter = DateFormatter()
                    apiDateFormatter.dateFormat = "dd-MM-yyyy"
                    
                    var todayDataFound = false
                    
                    // Process all days from the calendar response
                    for (_, dayData) in response.data.enumerated() {
                        // Parse the API's date to determine which day this data represents
                        guard let apiDate = apiDateFormatter.date(from: dayData.date.gregorian.date) else {
                            print("Failed to parse API date: \(dayData.date.gregorian.date)")
                            continue
                        }
                        
                        let apiDayStart = calendar.startOfDay(for: apiDate)
                        let isToday = apiDayStart == today
                        let isFuture = apiDayStart > today
                        
                        // Update UI info with today's data when we find it
                        if isToday && !todayDataFound {
                            self.timings = dayData.timings
                            self.readableDate = dayData.date.readable
                            self.hijriDate = dayData.date.hijri.date
                            todayDataFound = true
                        }
                        
                        // Convert timings to Date objects with unique keys for each day
                        for (name, timeString) in dayData.timings {
                            guard self.allowedPrayerKeys.contains(name) else { continue }
                            if let prayerDate = dateFormatter.date(from: timeString) {
                                // For today's prayers, filter out past times
                                if isToday && prayerDate <= now {
                                    continue // Skip past prayer times for today
                                }
                                
                                // Skip past days entirely
                                if !isToday && !isFuture {
                                    continue // Skip past dates
                                }
                                
                                // Use a unique key that includes the day for multi-day storage
                                let dayPrefix = isToday ? "" : "Tomorrow_"
                                self.prayerTimes[dayPrefix + name] = prayerDate
                            } else {
                                print("Failed to parse \(name): \(timeString)")
                            }
                        }
                    }
                    
                    // Now calculate next prayer with all available data
                    self.updateNextPrayer()
                }
            } catch {
                print("Decoding error: \(error)")
            }
        }.resume()
    }
}
