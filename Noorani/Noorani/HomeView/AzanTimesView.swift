//
//  AzanTimesView.swift
//  Noorani
//
//  Created by Amin Pourgol on 10/4/25.
//  Copyright © 2025 AP Bros. All rights reserved.
//

import SwiftUI
import Foundation

struct AzanTimesView: View {
    @ObservedObject var fetcher: PrayerTimesFetcher
    @AppStorage("currentCity") private var currentCity = ""
    @AppStorage("timeFormat") private var timeFormat: String = "12" // "12" or "24"
    @StateObject private var locationManager = LocationManager()
    @State private var refreshID = UUID() // Force view refresh when settings change

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Use dynamic prayer keys based on user preferences
            let orderedKeys = fetcher.visiblePrayerKeys

            if fetcher.isLoading || fetcher.timings.isEmpty {
                Spacer()
                ProgressView()
                Spacer()
            } else {
                ScrollView {
                    VStack(spacing: 14) {
                        ForEach(orderedKeys, id: \.self) { key in
                            if let value = fetcher.timings[key] {
                                Capsule()
                                    .stroke(Color.nooraniTextPrimary, style: StrokeStyle(lineWidth: 1))
                                    .frame(height: 50)
                                    .foregroundStyle(.clear)
                                    .overlay {
                                        HStack {
                                            Text(key)
                                            Spacer()
                                            Text(formatTime(value))
                                        }
                                        .font(.custom("Nunito-Regular", size: 30))
                                        .foregroundColor(.nooraniTextPrimary)
                                        .padding(.horizontal)
                                    }
                            }
                        }
                    }
                    .id(refreshID) // Force refresh when this ID changes
                    .padding(.horizontal, 22)
                    .padding(.vertical, 1)
                }
                .refreshable {
                    // Pull to refresh
                    fetcher.refreshPrayerTimes()
                }

            }
        }
        .onChange(of: locationManager.latitude) { _, newValue in
            if let lat = newValue, let lng = locationManager.longitude {
                fetcher.fetchPrayerTimes(latitude: lat, longitude: lng)
            }
        }
        .onChange(of: currentCity) { _, newCity in
            guard !newCity.isEmpty else { return }
            locationManager.getCoordinates(for: newCity) { coordinate in
                if let coordinate = coordinate {
                    fetcher.fetchPrayerTimes(latitude: coordinate.latitude, longitude: coordinate.longitude)
                } else {
                    print("Could not find coordinates for city: \(newCity)")
                }
            }
        }
        .onChange(of: timeFormat) { _, _ in
            // Force view refresh when time format changes
            refreshID = UUID()
        }
        .onChange(of: fetcher.showAsr) { _, _ in
            // Clear cache and refresh when Asr visibility changes
            fetcher.clearVisibleKeysCache()
            refreshID = UUID()
        }
        .onChange(of: fetcher.showIsha) { _, _ in
            // Clear cache and refresh when Isha visibility changes
            fetcher.clearVisibleKeysCache()
            refreshID = UUID()
        }
        .onChange(of: fetcher.showMidnight) { _, _ in
            // Clear cache and refresh when Midnight visibility changes
            fetcher.clearVisibleKeysCache()
            refreshID = UUID()
        }
    }

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
        
        // Format in the SELECTED LOCATION'S timezone (LA time, not your time)
        // This shows the actual local prayer time for that city
        let displayFormatter = DateFormatter()
        displayFormatter.timeZone = selectedLocationTimeZone ?? TimeZone.current
        
        // Set format based on user preference (independent of system settings)
        displayFormatter.locale = Locale(identifier: "en_US_POSIX") // Force consistent formatting
        
        if timeFormat == "12" {
            displayFormatter.dateFormat = "h:mm a"
        } else {
            displayFormatter.dateFormat = "HH:mm"
        }
        return displayFormatter.string(from: date)
    }


}

#Preview {
    AzanTimesView(fetcher: PrayerTimesFetcher())
}
