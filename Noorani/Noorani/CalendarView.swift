//
//  CalendarView.swift
//  Noorani
//
//  Created by Amin Pourgol on 11/7/25.
//

import SwiftUI
import MijickCalendarView

// MARK: - Main Calendar View
struct AzanCalendarView: View {
    @State private var selectedDate: Date? = Date()
    @State private var selectedRange: MDateRange? = nil
    @State private var prayerTimes: [PrayerTime] = []
    @State private var hijriDate: String = ""
    @State private var isLoading: Bool = false
    
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
    func createNavigationHeader() -> some View {
        VStack(spacing: 12) {
            HStack {
                // Previous Month Button
                Button(action: {
                    // Add previous month logic here
                }) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(.blue)
                        .frame(width: 44, height: 44)
                }
                
                Spacer()
                
                // Month and Year Display
                Text(getMonthYearString())
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                // Next Month Button
                Button(action: {
                    // Add next month logic here
                }) {
                    Image(systemName: "chevron.right")
                        .font(.title2)
                        .foregroundColor(.blue)
                        .frame(width: 44, height: 44)
                }
            }
            
            // Today Button
            Button(action: {
                selectedDate = Date()
            }) {
                Text("Today")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(Color.blue)
                    .cornerRadius(16)
            }
        }
        .padding(.horizontal)
    }
    
    func createCalendarView() -> some View {
        MCalendarView(
            selectedDate: $selectedDate,
            selectedRange: $selectedRange,
            configBuilder: configureCalendar
        )
        .frame(maxHeight: .infinity)
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
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("Select a date")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Choose a date from the calendar to view prayer times")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
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

// MARK: - Calendar Configuration
private extension AzanCalendarView {
    func configureCalendar(_ config: CalendarConfig) -> CalendarConfig {
        config
            .monthsTopPadding(8)
            .monthsBottomPadding(16)
    }
}

// MARK: - Helper Functions
private extension AzanCalendarView {
    func getMonthYearString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: selectedDate ?? Date())
    }
    
    func getDateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        return formatter.string(from: date)
    }
    
    func fetchPrayerTimes(for date: Date) {
        isLoading = true
        prayerTimes = []
        hijriDate = ""
        
        // Format date as DD-MM-YYYY for API
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yyyy"
        let dateString = formatter.string(from: date)
        
        // Build API URL using AppStorage values
        let urlString = "https://api.aladhan.com/v1/timings/\(dateString)?latitude=\(currentLat)&longitude=\(currentLng)&method=\(selectedMethodId)&iso8601=true&midnightMode=1"
        
        guard let url = URL(string: urlString) else {
            isLoading = false
            return
        }
        
        // Make API request
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                
                guard let data = data, error == nil else {
                    print("Error fetching prayer times: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                do {
                    let result = try JSONDecoder().decode(PrayerResponse.self, from: data)
                    prayerTimes = parsePrayerTimes(from: result.data.timings)
                    hijriDate = formatHijriDate(from: result.data.date.hijri)
                } catch {
                    print("Error decoding prayer times: \(error)")
                }
            }
        }.resume()
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
