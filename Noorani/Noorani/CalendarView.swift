//
//  CalendarView.swift
//  Noorani
//
//  Created by Amin Pourgol on 11/7/25.
//

import SwiftUI

// MARK: - Main Calendar View
struct AzanCalendarView: View {
    @State private var selectedDate: Date? = Date()
    @State private var displayedMonth: Date = Date()
    @State private var prayerTimes: [PrayerTime] = []
    @State private var hijriDate: String = ""
    @State private var isLoading: Bool = false
    @State private var isShowingCachedData: Bool = false  // Track if showing offline data

    // AppStorage values
    @AppStorage("showAsr") var showAsr: Bool = false // Hidden by default for Shia
    @AppStorage("showIsha") var showIsha: Bool = false // Hidden by default for Shia
    @AppStorage("currentLat") var currentLat: Double = 0.0
    @AppStorage("currentLng") var currentLng: Double = 0.0
    @AppStorage("selectedMethodId") private var selectedMethodId: Int = 7 // Default to TEHRAN for Shia
    @AppStorage("timeFormat") var timeFormat: String = "12" // Add this line
    
    var body: some View {
        ZStack(alignment: .top) {
            // gradient: #fab555 → #feecd3 → white
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: Color(hex: "#fab555"), location: 0.0), // Yellow/orange
                    .init(color: Color(hex: "#feecd3"), location: 0.55), // Light cream
                    .init(color: Color.white, location: 1.0)  // White
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(.all, edges: .vertical)
            VStack(spacing: 0) {
                // Offline indicator banner
                if isShowingCachedData {
                    HStack(spacing: 8) {
                        Image(systemName: "wifi.slash")
                            .font(.caption)
                        Text("Offline - Showing cached times")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.orange)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(Color.orange.opacity(0.15))
                }

                // Calendar
                createCalendarView()

                Divider()
                    .padding(.vertical, 8)

                // Azan Times Section
                if let selected = selectedDate {
                    if isLoading {
                        createLoadingView()
                    } else if prayerTimes.isEmpty {
                        createEmptyStateView()
                    } else {
                        createAzanTimesSection(for: selected)
                    }
                } else {
                    createEmptyStateView()
                }
            }
            .padding()
            .onAppear {
                if let date = selectedDate {
                    fetchPrayerTimes(for: date)
                }
            }
            .onChange(of: selectedDate) { oldValue, newValue in
                if let date = newValue {
                    fetchPrayerTimes(for: date)
                }
            }
            .onChange(of: timeFormat) { oldValue, newValue in
                // Refresh prayer times when time format changes
                if let date = selectedDate {
                    fetchPrayerTimes(for: date)
                }
            }
        }
    }
}

// MARK: - View Components
private extension AzanCalendarView {
    func createCalendarView() -> some View {
        VStack(spacing: 12) {
            createMonthHeader()
            createWeekdayHeader()
            createDayGrid()
        }
        .padding(.top, 8)
    }

    func createMonthHeader() -> some View {
        HStack {
            // Previous Month Button
            Button(action: { changeMonth(by: -1) }) {
                Image(systemName: "chevron.left")
                    .font(.title3.weight(.semibold))
                    .foregroundColor(.primary)
                    .frame(width: 44, height: 44)
            }

            Spacer()

            VStack(spacing: 2) {
                // Month and Year Display
                Text(getMonthYearString())
                    .font(.title3)
                    .fontWeight(.semibold)

                // Quick jump back to today when browsing another month
                if !calendar.isDate(displayedMonth, equalTo: Date(), toGranularity: .month) {
                    Button(action: {
                        selectedDate = Date()
                        displayedMonth = Date()
                    }) {
                        Text("Today")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(Color(hex: "#b8791f"))
                    }
                }
            }

            Spacer()

            // Next Month Button
            Button(action: { changeMonth(by: 1) }) {
                Image(systemName: "chevron.right")
                    .font(.title3.weight(.semibold))
                    .foregroundColor(.primary)
                    .frame(width: 44, height: 44)
            }
        }
    }

    func createWeekdayHeader() -> some View {
        HStack(spacing: 0) {
            ForEach(Array(calendar.veryShortWeekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                Text(symbol)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    func createDayGrid() -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 6) {
            ForEach(Array(makeDayGrid().enumerated()), id: \.offset) { _, day in
                if let day {
                    createDayCell(for: day)
                } else {
                    Color.clear
                        .frame(height: 38)
                }
            }
        }
    }

    func createDayCell(for day: Date) -> some View {
        let isSelected = selectedDate.map { calendar.isDate($0, inSameDayAs: day) } ?? false
        let isToday = calendar.isDateInToday(day)

        return Button(action: { selectedDate = day }) {
            Text("\(calendar.component(.day, from: day))")
                .font(.subheadline)
                .fontWeight(isSelected || isToday ? .bold : .regular)
                .foregroundColor(isSelected ? .white : .primary)
                .frame(maxWidth: .infinity)
                .frame(height: 38)
                .background(
                    ZStack {
                        if isSelected {
                            Circle()
                                .fill(Color(hex: "#fab555"))
                                .frame(width: 36, height: 36)
                        } else if isToday {
                            Circle()
                                .stroke(Color(hex: "#fab555"), lineWidth: 1.5)
                                .frame(width: 36, height: 36)
                        }
                    }
                )
        }
        .buttonStyle(.plain)
    }
    
    func createAzanTimesSection(for date: Date) -> some View {
        VStack(alignment: .center, spacing: 12) {
            VStack(alignment: .center, spacing: 4) {
                Text("Prayer Times")
                    .font(.title3)
                    .bold()
                    .frame(maxWidth: .infinity, alignment: .center)

                HStack(spacing: 6) {
                    Text(getDateString(from: date))
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    if !hijriDate.isEmpty {
                        Text("•")
                            .foregroundColor(.secondary)

                        Text(hijriDate)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .frame(maxWidth: .infinity, alignment: .center)
            }

            // Two-column grid for Azan times - centered
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 10),
                    GridItem(.flexible(), spacing: 10)
                ],
                spacing: 10
            ) {
                ForEach(prayerTimes, id: \.name) { time in
                    createAzanTimeCard(name: time.name, time: time.time, icon: time.icon)
                }
            }
            .padding(.horizontal)
        }
        .frame(maxHeight: .infinity, alignment: .top)
    }
    
    func createEmptyStateView() -> some View {
        VStack(spacing: 16) {
            Spacer()

            // Always show offline state
            VStack(spacing: 12) {
                Image(systemName: "wifi.slash")
                    .font(.system(size: 44))
                    .foregroundColor(.orange)

                Text("Offline")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                Text("Connect to internet to view more days")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Spacer()
        }
        .frame(maxHeight: .infinity)
        .padding()
    }
    
    func createLoadingView() -> some View {
        VStack(spacing: 12) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Loading prayer times...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxHeight: .infinity)
        .padding()
    }
    
    func createAzanTimeCard(name: String, time: String, icon: String) -> some View {
        HStack(spacing: 10) {
            // Icon - no circle background
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color(hex: "#fab555"))
                .frame(width: 24, height: 24)

            // Prayer name and time - centered
            VStack(alignment: .center, spacing: 2) {
                Text(name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                Text(time)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(hex: "#fab555").opacity(0.15))
        .cornerRadius(12)
    }
}

// MARK: - Helper Functions
private extension AzanCalendarView {
    /// Gregorian calendar with Sunday as the first weekday (matches the app's week layout)
    var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = 1
        return cal
    }

    func changeMonth(by offset: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: offset, to: displayedMonth) {
            displayedMonth = newMonth
        }
    }

    /// Days of the displayed month, padded with nil so the first row aligns to the weekday columns
    func makeDayGrid() -> [Date?] {
        guard let monthStart = calendar.dateInterval(of: .month, for: displayedMonth)?.start,
              let dayCount = calendar.range(of: .day, in: .month, for: displayedMonth)?.count else {
            return []
        }

        let leadingBlanks = (calendar.component(.weekday, from: monthStart) - calendar.firstWeekday + 7) % 7
        var days: [Date?] = Array(repeating: nil, count: leadingBlanks)
        for offset in 0..<dayCount {
            days.append(calendar.date(byAdding: .day, value: offset, to: monthStart))
        }
        return days
    }

    func getMonthYearString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: displayedMonth)
    }
    
    func getDateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        return formatter.string(from: date)
    }
    
    func fetchPrayerTimes(for date: Date) {
        // Format date as DD-MM-YYYY for API/Cache
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yyyy"
        let dateString = formatter.string(from: date)

        // Try to load cached prayer times first for instant display
        // Don't show offline banner yet - wait to see if network fetch succeeds
        if let cachedData = UserDefaults.standard.data(forKey: "cachedPrayerTimes_\(dateString)"),
           let cache = try? JSONDecoder().decode(CachedPrayerTimes.self, from: cachedData) {
            // Load cached data immediately
            let cachedPrayerTimesDict = cache.toPrayerTimes()

            // Convert cached times to formatted strings
            var cachedTimings: [String: String] = [:]
            let timeFormatter = DateFormatter()

            // Use the current timezone for displaying cached times
            // The Date objects already contain the correct absolute time
            timeFormatter.timeZone = TimeZone.current

            if timeFormat == "24" {
                timeFormatter.dateFormat = "HH:mm"
            } else {
                timeFormatter.dateFormat = "h:mm a"
            }

            for (name, time) in cachedPrayerTimesDict {
                cachedTimings[name] = timeFormatter.string(from: time)
            }

            prayerTimes = parsePrayerTimings(cachedTimings)
            hijriDate = cache.hijriDate.isEmpty ? "" : cache.hijriDate
            // Don't set isShowingCachedData yet - let network fetch determine this
            isLoading = false

            print("📂 Loaded cached prayer times for \(dateString)")
        } else {
            isLoading = true
            prayerTimes = []
            hijriDate = ""
            isShowingCachedData = false
        }

        // Build API URL using AppStorage values
        let urlString = "https://api.aladhan.com/v1/timings/\(dateString)?latitude=\(currentLat)&longitude=\(currentLng)&method=\(selectedMethodId)&iso8601=true&midnightMode=1"

        guard let url = URL(string: urlString) else {
            isLoading = false
            return
        }

        // Make API request (fetch fresh data in background, even if we have cache)
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false

                guard let data = data, error == nil else {
                    print("Error fetching prayer times: \(error?.localizedDescription ?? "Unknown error")")
                    // Only show offline banner if we have cached data to display
                    if !prayerTimes.isEmpty {
                        isShowingCachedData = true
                        print("📶 Network unavailable, showing cached data")
                    }
                    return
                }

                do {
                    let result = try JSONDecoder().decode(PrayerResponse.self, from: data)
                    prayerTimes = parsePrayerTimes(from: result.data.timings)
                    hijriDate = formatHijriDate(from: result.data.date.hijri)
                    isShowingCachedData = false  // Now showing fresh data
                    print("✅ Loaded fresh prayer times for \(dateString)")
                } catch {
                    print("Error decoding prayer times: \(error)")
                    // Show offline banner if we have cached data but decode failed
                    if !prayerTimes.isEmpty {
                        isShowingCachedData = true
                    }
                }
            }
        }.resume()
    }

    // Helper to parse timings when we already have formatted strings (from cache)
    func parsePrayerTimings(_ timings: [String: String]) -> [PrayerTime] {
        var times: [PrayerTime] = [
            PrayerTime(name: "Fajr", time: timings["Fajr"] ?? "", icon: "sunrise.fill"),
            PrayerTime(name: "Sunrise", time: timings["Sunrise"] ?? "", icon: "sun.horizon.fill"),
            PrayerTime(name: "Dhuhr", time: timings["Dhuhr"] ?? "", icon: "sun.max.fill")
        ]

        if showAsr {
            times.append(PrayerTime(name: "Asr", time: timings["Asr"] ?? "", icon: "sun.min.fill"))
        }

        times.append(PrayerTime(name: "Sunset", time: timings["Sunset"] ?? "", icon: "sunset.fill"))
        times.append(PrayerTime(name: "Maghrib", time: timings["Maghrib"] ?? "", icon: "moon.fill"))

        if showIsha {
            times.append(PrayerTime(name: "Isha", time: timings["Isha"] ?? "", icon: "moon.stars.fill"))
        }

        times.append(PrayerTime(name: "Midnight", time: timings["Midnight"] ?? "", icon: "moon.zzz.fill"))

        return times
    }
    
    func parsePrayerTimes(from timings: [String: String]) -> [PrayerTime] {
        func formatTime(_ isoString: String) -> String {
            // Parse ISO8601 format (which includes timezone info)
            let iso8601Formatter = ISO8601DateFormatter()
            iso8601Formatter.formatOptions = [.withInternetDateTime]

            guard let date = iso8601Formatter.date(from: isoString) else {
                return isoString // Fallback to original string if parsing fails
            }

            // Extract the timezone from the ISO string to show the LOCAL time of the selected city
            let timeZoneRegex = /([+-]\d{2}):(\d{2})$/
            var selectedLocationTimeZone: TimeZone?

            if let match = isoString.firstMatch(of: timeZoneRegex) {
                let hours = Int(match.1) ?? 0
                let minutes = Int(match.2) ?? 0
                let totalSeconds = (abs(hours) * 3600) + (minutes * 60)
                let offsetSeconds = match.1.hasPrefix("-") ? -totalSeconds : totalSeconds
                selectedLocationTimeZone = TimeZone(secondsFromGMT: offsetSeconds)
            }

            // Format in the SELECTED LOCATION'S timezone (not user's local timezone)
            // This shows the actual local prayer time for that city
            let displayFormatter = DateFormatter()
            displayFormatter.timeZone = selectedLocationTimeZone ?? TimeZone.current
            displayFormatter.locale = Locale(identifier: "en_US_POSIX") // consistent formatting

            // Use timeFormat AppStorage value to set format
            if timeFormat == "24" {
                displayFormatter.dateFormat = "HH:mm"
            } else {
                displayFormatter.dateFormat = "h:mm a"
            }

            return displayFormatter.string(from: date)
        }
        
        var times: [PrayerTime] = [
            PrayerTime(name: "Fajr", time: formatTime(timings["Fajr"] ?? ""), icon: "sunrise.fill"),
            PrayerTime(name: "Sunrise", time: formatTime(timings["Sunrise"] ?? ""), icon: "sun.horizon.fill"),
            PrayerTime(name: "Dhuhr", time: formatTime(timings["Dhuhr"] ?? ""), icon: "sun.max.fill")
        ]
        
        // Only show Asr if enabled
        if showAsr {
            times.append(PrayerTime(name: "Asr", time: formatTime(timings["Asr"] ?? ""), icon: "sun.min.fill"))
        }
        
        times.append(PrayerTime(name: "Sunset", time: formatTime(timings["Sunset"] ?? ""), icon: "sunset.fill"))
        times.append(PrayerTime(name: "Maghrib", time: formatTime(timings["Maghrib"] ?? ""), icon: "moon.fill"))
        
        // Only show Isha if enabled
        if showIsha {
            times.append(PrayerTime(name: "Isha", time: formatTime(timings["Isha"] ?? ""), icon: "moon.stars.fill"))
        }
        
        times.append(PrayerTime(name: "Midnight", time: formatTime(timings["Midnight"] ?? ""), icon: "moon.zzz.fill"))
        
        return times
    }
    
    func formatHijriDate(from hijri: HijriDate) -> String {
            // Remove accents/diacritics from month name
            let monthName = hijri.month.en.folding(options: .diacriticInsensitive, locale: .current)
            return "\(hijri.day) \(monthName) \(hijri.year) AH"
        }
}

// MARK: - Prayer Time Model
struct PrayerTime {
    let name: String
    let time: String
    let icon: String
}

// MARK: - Preview
#Preview {
    AzanCalendarView()
}
