//
//  ContentViewModel.swift
//  Noorani
//  Copyright © 2025 AP Bros. All rights reserved.
 
  

//

import Foundation
import SwiftUI

@MainActor
class ContentViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var selectedTab = 0

    // MARK: - Dependencies
    private let prayerTimesFetcher: PrayerTimesFetcher
    private let locationManager: LocationManager
    
    // Track if we've already requested location to prevent multiple calls
    private var hasRequestedLocation = false

    // Debounce rapid location changes (prevent duplicate calls from lat/lng onChange)
    private var locationUpdateTask: Task<Void, Never>?

    // MARK: - Initialization
    init(prayerTimesFetcher: PrayerTimesFetcher, locationManager: LocationManager) {
        self.prayerTimesFetcher = prayerTimesFetcher
        self.locationManager = locationManager

        // Simple initialization - just request location once
        requestLocationAndFetchPrayers()
    }

    // MARK: - Private Methods
    private func requestLocationAndFetchPrayers() {
        guard !hasRequestedLocation else { return }
        hasRequestedLocation = true
        
        // Check if we already have stored coordinates
        if prayerTimesFetcher.currentLat != 0.0 && prayerTimesFetcher.currentLng != 0.0 {
            // We have cached coordinates, use them to fetch prayer times
            Task {
                await prayerTimesFetcher.fetchPrayerTimes(
                    latitude: prayerTimesFetcher.currentLat,
                    longitude: prayerTimesFetcher.currentLng
                )
            }
        } else {
            // No cached coordinates, request location
            locationManager.requestLocation {
                // The onChange handler in ContentView will take care of the location update
            }
        }
    }

    // MARK: - Public Methods
    func handleLocationChange(latitude: Double?, longitude: Double?) {
        guard let lat = latitude, let lng = longitude else { return }

        // Cancel any pending update to debounce rapid changes
        locationUpdateTask?.cancel()

        // Debounce: wait 300ms to batch lat/lng changes together
        locationUpdateTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds

            guard !Task.isCancelled else { return }

            // Get stored coordinates
            let oldLat = prayerTimesFetcher.currentLat
            let oldLng = prayerTimesFetcher.currentLng

            // Check if coordinates actually changed
            let coordsChanged = (oldLat != lat || oldLng != lng)

            guard coordsChanged else {
                print("📍 Coordinates unchanged, skipping update")
                return
            }

            // Check if this is first time or if location changed
            if oldLat == 0.0 || oldLng == 0.0 {
                // First time - always update
                print("📍 First location detected, updating prayer times...")
                await prayerTimesFetcher.updateLocation(latitude: lat, longitude: lng)
            } else {
                // Calculate distance change
                let distance = LocationUtils.calculateDistance(
                    lat1: oldLat,
                    lon1: oldLng,
                    lat2: lat,
                    lon2: lng
                )

                // ALWAYS update if coordinates changed - user might have selected a different city
                // Remove the 1.6km threshold that was blocking manual city changes!
                if distance > 0.01 { // Minimum 10 meters to avoid GPS drift
                    print("📍 Location changed by \(String(format: "%.1f", distance))km, updating prayer times...")
                    await prayerTimesFetcher.updateLocation(latitude: lat, longitude: lng)
                } else {
                    print("📍 Location change minimal (\(String(format: "%.2f", distance))km), using cached prayer times")
                    // Still update the stored coordinates to reflect current position
                    prayerTimesFetcher.currentLat = lat
                    prayerTimesFetcher.currentLng = lng
                }
            }
        }
    }
}
