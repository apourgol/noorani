//
//  NooraniWidgetBundle.swift
//  NooraniWidget
//  Copyright © 2025 AP Bros. All rights reserved.
//

import WidgetKit
import SwiftUI

@main
struct NooraniWidgetBundle: WidgetBundle {
    var body: some Widget {
        if #available(iOS 16.1, *) {
            PrayerCountdownLiveActivity()
        }
    }
}
