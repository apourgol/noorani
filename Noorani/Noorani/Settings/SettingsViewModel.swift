//
//  SettingsViewModel.swift
//  Noorani
//  Copyright © 2025 AP Bros. All rights reserved.
 
  

//

import Foundation
import SwiftUI

@MainActor
class SettingsViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var showingCalculationView = false
    @Published var showingCalendarView = false
    @Published var showingNotificationsView = false
    @Published var showingAboutView = false
    @Published var showingResetAlert = false
    
    // MARK: - Dependencies
    private let prayerTimesFetcher: PrayerTimesFetcher
    
    // MARK: - Initialization
    init(prayerTimesFetcher: PrayerTimesFetcher) {
        self.prayerTimesFetcher = prayerTimesFetcher
    }
    
    // MARK: - Public Methods
    func showCalculationView() {
        showingCalculationView = true
    }
    
    func showCalendarView() {
        showingCalendarView = true
    }
    
    func showNotificationsView() {
        showingNotificationsView = true
    }
    
    func showAboutView() {
        showingAboutView = true
    }
    
    func showResetAlert() {
        showingResetAlert = true
    }

    @Published var showingPrivacyPolicyView = false
    @Published var showingTermsOfServiceView = false

    func showPrivacyPolicyView() {
        showingPrivacyPolicyView = true
    }

    func showTermsOfServiceView() {
        showingTermsOfServiceView = true
    }

    func resetToDefaults() {
        // Reset all UserDefaults/AppStorage values to defaults
        UserDefaults.standard.removeObject(forKey: "timeFormat")
        UserDefaults.standard.removeObject(forKey: "selectedCalculationMethod")
        UserDefaults.standard.removeObject(forKey: "notificationsEnabled")
        UserDefaults.standard.removeObject(forKey: "calendarType")
        UserDefaults.standard.removeObject(forKey: "currentCity")
        // Add other settings keys as needed
        
        // Notify prayer fetcher to reset to defaults
        prayerTimesFetcher.resetToDefaults()
    }
}
