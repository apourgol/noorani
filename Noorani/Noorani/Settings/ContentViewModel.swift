//
//  ContentViewModel.swift
//  Noorani
//
//  Created by AP Bros on 11/4/25.
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
        
        // Update location and fetch prayer times for the new location
        Task {
            await prayerTimesFetcher.updateLocation(latitude: lat, longitude: lng)
        }
    }
}
