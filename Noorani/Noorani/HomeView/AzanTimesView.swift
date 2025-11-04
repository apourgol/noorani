//
//  AzanTimesView.swift
//  Noorani
//
//  Created by Amin Pourgol on 10/4/25.
//  Copyright © 2025 AP Bros. All rights reserved.
//

import SwiftUI
import Foundation

struct AzanTimesView: View {
    @ObservedObject var fetcher: PrayerTimesFetcher
    @StateObject private var viewModel: AzanTimesViewModel
    @StateObject private var locationManager = LocationManager()
    
    // Custom initializer to inject dependencies
    init(fetcher: PrayerTimesFetcher) {
        self.fetcher = fetcher
        // We need to use a private property to create the StateObject
        self._viewModel = StateObject(wrappedValue: AzanTimesViewModel(
            prayerTimesFetcher: fetcher,
            locationManager: LocationManager()
        ))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if viewModel.isLoading || viewModel.timings.isEmpty {
                Spacer()
                ProgressView()
                Spacer()
            } else {
                ScrollView {
                    VStack(spacing: 14) {
                        ForEach(viewModel.visiblePrayerKeys, id: \.self) { key in
                            if let value = viewModel.timings[key] {
                                PrayerTimeRow(
                                    prayerName: key,
                                    prayerTime: viewModel.formatTime(value)
                                )
                            }
                        }
                    }
                    .id(viewModel.refreshID) // refresh when this ID changes
                    .padding(.horizontal, 22)
                    .padding(.vertical, 1)
                }
                .refreshable {
                    // Pull to refresh
                    viewModel.refreshPrayerTimes()
                }
            }
        }
        .onChange(of: fetcher.showAsr) { _, _ in
            viewModel.triggerRefresh()
        }
        .onChange(of: fetcher.showIsha) { _, _ in
            viewModel.triggerRefresh()
        }
        // Note: Midnight is always visible - no onChange needed
    }
}

// MARK: - Prayer Time Row Component
struct PrayerTimeRow: View {
    let prayerName: String
    let prayerTime: String
    
    var body: some View {
        Capsule()
            .stroke(Color.nooraniTextPrimary, style: StrokeStyle(lineWidth: 1))
            .frame(height: 50)
            .foregroundStyle(.clear)
            .overlay {
                HStack {
                    Text(prayerName)
                    Spacer()
                    Text(prayerTime)
                }
                .font(.custom("Nunito-Regular", size: 30))
                .foregroundColor(.nooraniTextPrimary)
                .padding(.horizontal)
            }
    }
}

#Preview {
    AzanTimesView(fetcher: PrayerTimesFetcher())
}
