//
//  AzanTimesViewModel.swift
//  Noorani
//
//  Created by AP Bros on 11/4/25.
//  Copyright © 2025 AP Bros. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class AzanTimesViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var refreshID = UUID()
    @AppStorage("timeFormat") var timeFormat: String = "12" // Using AppStorage for instant sync across views
    @Published var currentCity: String = ""

    // MARK: - Dependencies
    private let prayerTimesFetcher: PrayerTimesFetcher
    private let locationManager: LocationManager
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization
    init(prayerTimesFetcher: PrayerTimesFetcher, locationManager: LocationManager) {
        self.prayerTimesFetcher = prayerTimesFetcher
        self.locationManager = locationManager

        // Load user preferences
        loadUserPreferences()

        // Set up reactive bindings
        setupBindings()
    }

    // MARK: - Private Methods
    private func loadUserPreferences() {
        // Load from UserDefaults using the same keys as AppStorage
        currentCity = UserDefaults.standard.string(forKey: "currentCity") ?? ""
    }

    private func setupBindings() {
        // React to city changes
        $currentCity
            .dropFirst() // Skip initial value
            .sink { [weak self] newCity in
                self?.handleCityChange(newCity)
            }
            .store(in: &cancellables)

        // React to location manager changes
        locationManager.$latitude
            .combineLatest(locationManager.$longitude)
            .sink { [weak self] lat, lng in
                self?.handleLocationChange(latitude: lat, longitude: lng)
            }
            .store(in: &cancellables)

        // Note: Prayer visibility changes are handled directly in PrayerTimeCalculationViewModel
        // We'll manually trigger refresh when needed
    }

    private func handleCityChange(_ newCity: String) {
        guard !newCity.isEmpty else { return }

        // Save to UserDefaults
        UserDefaults.standard.set(newCity, forKey: "currentCity")

        // Get coordinates for the new city
        locationManager.getCoordinates(for: newCity) { [weak self] coordinate in
            if let coordinate = coordinate, let strongSelf = self {
                Task {
                    await strongSelf.prayerTimesFetcher.fetchPrayerTimes(
                        latitude: coordinate.latitude,
                        longitude: coordinate.longitude
                    )
                }
            } else {
                print("Could not find coordinates for city: \(newCity)")
            }
        }
    }

    private func handleLocationChange(latitude: Double?, longitude: Double?) {
        if let lat = latitude, let lng = longitude {
            Task {
                await prayerTimesFetcher.fetchPrayerTimes(latitude: lat, longitude: lng)
            }
        }
    }

    // MARK: - Public Methods
    func refreshPrayerTimes() {
        prayerTimesFetcher.refreshPrayerTimes()
    }

    func triggerRefresh() {
        // Called when prayer visibility changes from the UI
        refreshID = UUID()
    }

    // MARK: - Time Formatting Logic (moved from View)
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

        // Format in the SELECTED LOCATION'S timezone (LA time, not local time - prevents praytime.info FAILS!)
        // This shows the actual local prayer time for that city
        let displayFormatter = DateFormatter()
        displayFormatter.timeZone = selectedLocationTimeZone ?? TimeZone.current

        // Set format based on user preference (independent of system settings)
        displayFormatter.locale = Locale(identifier: "en_US_POSIX") // consistent formatting

        if timeFormat == "12" {
            displayFormatter.dateFormat = "h:mm a"
        } else {
            displayFormatter.dateFormat = "HH:mm"
        }
        return displayFormatter.string(from: date)
    }

    // MARK: - Computed Properties
    var visiblePrayerKeys: [String] {
        return prayerTimesFetcher.visiblePrayerKeys
    }

    var isLoading: Bool {
        return prayerTimesFetcher.isLoading
    }

    var timings: [String: String] {
        return prayerTimesFetcher.timings
    }
}
