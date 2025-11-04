//
//  CalendarSettingViewModel.swift
//  Noorani
//
//  Created by AP Bros on 11/4/25.
//  Copyright © 2025 AP Bros. All rights reserved.
//

import Foundation
import SwiftUI

@MainActor
class CalendarSettingViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var calendarType: String = "both" // "hijri", "gregorian", "both"
    @Published var hijriOffset: Int = 0 // Offset for Hijri date adjustment
    
    // MARK: - Initialization
    init() {
        loadSettings()
    }
    
    // MARK: - Private Methods
    private func loadSettings() {
        calendarType = UserDefaults.standard.string(forKey: "calendarType") ?? "both"
        hijriOffset = UserDefaults.standard.integer(forKey: "hijriOffset")
    }
    
    // MARK: - Public Methods
    func updateCalendarType(_ type: String) {
        calendarType = type
        UserDefaults.standard.set(type, forKey: "calendarType")
    }
    
    func updateHijriOffset(_ offset: Int) {
        hijriOffset = offset
        UserDefaults.standard.set(offset, forKey: "hijriOffset")
    }
    
    func incrementHijriOffset() {
        let newOffset = min(hijriOffset + 1, 2) // Max +2
        updateHijriOffset(newOffset)
    }
    
    func decrementHijriOffset() {
        let newOffset = max(hijriOffset - 1, -2) // Min -2
        updateHijriOffset(newOffset)
    }
    
    // MARK: - Computed Properties
    var hijriOffsetString: String {
        if hijriOffset == 0 {
            return "±0"
        } else if hijriOffset > 0 {
            return "+\(hijriOffset)"
        } else {
            return "\(hijriOffset)"
        }
    }
}
