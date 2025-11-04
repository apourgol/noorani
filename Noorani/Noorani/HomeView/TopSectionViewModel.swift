//
//  TopSectionViewModel.swift
//  Noorani
//
//  Copyright © 2025 AP Bros. All rights reserved.
//

import Foundation
import SwiftUI

@MainActor
class TopSectionViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var showLocationMenu: Bool = false
    
    // Use AppStorage directly as the source of truth
    @AppStorage("currentCity") var currentCity: String = ""
    
    // MARK: - Dependencies
    private let prayerTimesFetcher: PrayerTimesFetcher
    private let locationManager: LocationManager
    
    // MARK: - Initialization
    init(prayerTimesFetcher: PrayerTimesFetcher, locationManager: LocationManager) {
        self.prayerTimesFetcher = prayerTimesFetcher
        self.locationManager = locationManager
    }
    
    // MARK: - Public Methods
    func formatDateFromAdhanAPI(date: String) -> String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "dd MMM yyyy" // Matches "04 Oct 2025"

        guard let parsedDate = inputFormatter.date(from: date) else {
            return date // fallback if parsing fails
        }

        let outputFormatter = DateFormatter()
        outputFormatter.locale = Locale.current
        outputFormatter.dateStyle = .long

        return outputFormatter.string(from: parsedDate)
    }
    
    func getNextEventLabel(_ eventName: String) -> String {
        let prayerNames = ["Fajr", "Dhuhr", "Asr", "Maghrib", "Isha"]
        let nonPrayerEvents = ["Sunrise", "Sunset", "Midnight"]
        
        if prayerNames.contains(eventName) {
            return "Next Prayer"
        } else if nonPrayerEvents.contains(eventName) {
            return "Pray Before"
        } else {
            return "Next Prayer" // Default fallback
        }
    }
    
    func showLocationMenuAction() {
        showLocationMenu = true
    }
    
    // MARK: - Computed Properties
    var nextPrayerName: String {
        return prayerTimesFetcher.nextPrayerName
    }
    
    var countdown: String {
        return prayerTimesFetcher.countdown
    }
    
    var readableDate: String {
        return prayerTimesFetcher.readableDate
    }
    
    var isLocationLoading: Bool {
        return locationManager.isLoading
    }
}
