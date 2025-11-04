//
//  AboutViewModel.swift
//  Noorani
//
//  Created by AP Bros on 11/4/25.
//  Copyright © 2025 AP Bros. All rights reserved.
//

import Foundation
import SwiftUI

@MainActor
class AboutViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var navigationPath = NavigationPath()
    
    // MARK: - Constants
    let appName = "Noorani"
    let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    let copyright = "© 2025 AP Bros. All rights reserved."
    
    // MARK: - Public Methods
    func openPrivacyPolicy() {
        navigationPath.append("privacy")
    }
    
    func openTermsOfService() {
        navigationPath.append("terms")
    }
    
    // MARK: - Computed Properties
    var fullVersionString: String {
        return "Version \(appVersion) (\(buildNumber))"
    }
}
