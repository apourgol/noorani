//
//  LocationMenuViewModel.swift
//  Noorani
 //  Copyright © 2025 AP Bros. All rights reserved.

  

//

import Foundation
import SwiftUI

@MainActor
class LocationMenuViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var searchText = ""
    
    // MARK: - Constants
    let popularCities = [
        "New York, NY", "Los Angeles, CA", "Chicago, IL", "Houston, TX",
        "Fairfax, VA", "Philadelphia, PA", "Washington, D.C.", "San Diego, CA",
        "Dallas, TX", "Dearborn, MI", "Austin, TX", "Toronto, CA"
    ]
    
    // MARK: - Dependencies
    private let locationManager: LocationManager
    
    // MARK: - Initialization
    init(locationManager: LocationManager) {
        self.locationManager = locationManager
    }
    
    // MARK: - Public Methods
    func requestCurrentLocation(onCompletion: @escaping () -> Void) {
        // Set flag to indicate "current location" mode is active
        // This ensures location refreshes automatically when app opens
        UserDefaults.standard.set(true, forKey: "useCurrentLocation")

        locationManager.requestLocation {
            onCompletion()
        }
    }
    
    func selectCity(_ city: String, onCompletion: @escaping () -> Void) {
        // Save the selected city to UserDefaults
        UserDefaults.standard.set(city, forKey: "currentCity")

        // Disable "current location" mode since user manually selected a city
        UserDefaults.standard.set(false, forKey: "useCurrentLocation")

        // Get coordinates for the selected city
        locationManager.getCoordinates(for: city) { coordinate in
            if let coordinate = coordinate {
                // Update location manager with new coordinates
                DispatchQueue.main.async {
                    self.locationManager.latitude = coordinate.latitude
                    self.locationManager.longitude = coordinate.longitude
                    onCompletion()
                }
            } else {
                print("Could not find coordinates for city: \(city)")
                onCompletion()
            }
        }
    }
    
    // MARK: - Computed Properties
    var filteredCities: [String] {
        if searchText.isEmpty {
            return popularCities
        } else {
            return popularCities.filter { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var isLoading: Bool {
        return locationManager.isLoading
    }
}
