//
//  PrayerTimeCalculationViewModel.swift
//  Noorani
//  Copyright © 2025 AP Bros. All rights reserved.
 

//

import Foundation
import SwiftUI

@MainActor
class PrayerTimeCalculationViewModel: ObservableObject {
    // MARK: - Published Properties
    @AppStorage("timeFormat") var timeFormat: String = "12" // Using AppStorage for instant sync
    @Published var showAsr: Bool = false
    @Published var showIsha: Bool = false
    // Note: Midnight is always visible now - no toggle needed

    // MARK: - Dependencies
    private let prayerTimesFetcher: PrayerTimesFetcher

    // MARK: - Initialization
    init(prayerTimesFetcher: PrayerTimesFetcher) {
        self.prayerTimesFetcher = prayerTimesFetcher
        loadSettings()
    }

    // MARK: - Private Methods
    private func loadSettings() {
        // timeFormat is now loaded automatically via @AppStorage
        showAsr = prayerTimesFetcher.showAsr
        showIsha = prayerTimesFetcher.showIsha
        // Midnight is always visible - no need to load setting
    }

    // MARK: - Public Methods
    func updateTimeFormat(_ newFormat: String) {
        timeFormat = newFormat // @AppStorage automatically saves to UserDefaults and syncs everywhere
    }

    func selectCalculationMethod(_ method: PrayerCalculationMethod) {
        prayerTimesFetcher.selectMethod(method)
    }

    func updateShowAsr(_ value: Bool) {
        DispatchQueue.main.async {
            self.showAsr = value
            self.prayerTimesFetcher.showAsr = value
            self.prayerTimesFetcher.updateNextPrayerForVisibilityChange()
        }
    }

    func updateShowIsha(_ value: Bool) {
        DispatchQueue.main.async {
            self.showIsha = value
            self.prayerTimesFetcher.showIsha = value
            self.prayerTimesFetcher.updateNextPrayerForVisibilityChange()
        }
    }

    // Note: No updateShowMidnight method needed - Midnight is always visible

    // MARK: - Computed Properties
    var availableMethods: [PrayerCalculationMethod] {
        return prayerTimesFetcher.availableMethods
    }

    var selectedMethod: PrayerCalculationMethod? {
        return prayerTimesFetcher.selectedMethod
    }
}
