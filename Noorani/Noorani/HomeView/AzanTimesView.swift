//
//  AzanTimesView.swift
//  Noorani
//
//  Created by Amin Pourgol on 10/4/25.
//  Copyright © 2025 AP Bros. All rights reserved.
//

import SwiftUI

struct AzanTimesView: View {
    @ObservedObject var fetcher: PrayerTimesFetcher
    @AppStorage("currentCity") private var currentCity = ""
    @StateObject private var locationManager = LocationManager()
    
    @State var isLoading = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            let orderedKeys = ["Fajr", "Sunrise", "Dhuhr", "Sunset", "Maghrib", "Midnight"]
            
            if isLoading {
                Spacer()
                ProgressView()
                Spacer()
            } else {
                ScrollView {
                    VStack(spacing: 14) {
                        ForEach(orderedKeys, id: \.self) { key in
                            if let value = fetcher.timings[key] {
                                Capsule()
                                    .stroke(Color.black, style: StrokeStyle(lineWidth: 1))
                                    .frame(height: 50)
                                    .foregroundStyle(.clear)
                                    .overlay {
                                        HStack {
                                            Text(key)
                                            Spacer()
                                            Text(formatTime(value))
                                        }
                                        .font(.custom("Nunito-Regular", size: 30))
                                        .padding(.horizontal)
                                    }
                            }
                        }
                    }
                    .padding(.horizontal, 22)
                    .padding(.vertical, 1)
                }
                
            }
        }
        .onAppear {
            isLoading = true // TODO: This is causing a bug. We're seeing the loading happening after switching tabs. Needs fixing
        }
        .onChange(of: locationManager.latitude) {
            locationManager.requestLocation() {
                fetcher.fetchPrayerTimes(latitude: locationManager.latitude ?? 0, longitude: locationManager.longitude ?? 0)
            }
            isLoading = false
        }
        .onChange(of: currentCity) {
            locationManager.getCoordinates(for: currentCity) { coordinate in
                if let coordinate = coordinate {
                    fetcher.fetchPrayerTimes(latitude: coordinate.latitude, longitude: coordinate.longitude)
                } else {
                    print("Could not find coordinates.")
                }
            }
        }
    }
    
    func formatTime(_ isoString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: isoString) {
            let displayFormatter = DateFormatter()
            displayFormatter.timeStyle = .short
            displayFormatter.locale = Locale.current
            return displayFormatter.string(from: date)
        }
        return isoString
    }
}

#Preview {
    AzanTimesView(fetcher: PrayerTimesFetcher())
}
