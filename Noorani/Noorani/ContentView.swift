//
//  ContentView.swift
//  Noorani
//
//  Copyright © 2025 AP Bros. All rights reserved.

import SwiftUI

struct ContentView: View {
    @StateObject var fetcher = PrayerTimesFetcher()
    @StateObject private var locationManager = LocationManager()
    @StateObject private var viewModel: ContentViewModel
    
    // Custom initializer
    init() {
        let fetcher = PrayerTimesFetcher()
        let locationManager = LocationManager()
        
        self._fetcher = StateObject(wrappedValue: fetcher)
        self._locationManager = StateObject(wrappedValue: locationManager)
        self._viewModel = StateObject(wrappedValue: ContentViewModel(
            prayerTimesFetcher: fetcher,
            locationManager: locationManager
        ))
    }
    
    var body: some View {
        TabView {
            Tab("Prayer Times", systemImage: "sun.max") {
                ZStack(alignment: .top) {
                    // gradient: #fab555 → #feecd3 → white
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: Color(hex: "#fab555"), location: 0.0), // Yellow/orange
                            .init(color: Color(hex: "#feecd3"), location: 0.55), // Light cream
                            .init(color: Color.white, location: 1.0)  // White
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea(.all, edges: .vertical)
                    
                    VStack {
                        TopSectionView(prayerFetcher: fetcher, locationManager: locationManager)
                        AzanTimesView(fetcher: fetcher)
                    }
                }
                .tag(0)
            }
            
            Tab("Calendar", systemImage: "calendar") {
                AzanCalendarView()
                    .tag(1)
            }
                
            Tab("Holy Quran", systemImage: "text.book.closed.fill") {
                QuranView()
                    .tag(2)
            }
                
            Tab("Qibla", systemImage: "cube.fill") {
                QiblaFinderView(locationManager: locationManager)
                    .tag(3)
            }
                
            Tab("Settings", systemImage: "gearshape") {
                SettingsView(prayerFetcher: fetcher)
                    .tag(4)
            }
        }
        .tint(Color(hex: "#fab555")) // TODO: We should be adding the colors as assets
        .onAppear {
            // The ViewModel handles this automatically now
        }
        .onChange(of: locationManager.latitude) { _, newLat in
            if let newLat = newLat {
                viewModel.handleLocationChange(latitude: newLat, longitude: locationManager.longitude)
            }
        }
        .onChange(of: locationManager.longitude) { _, newLng in
            if let newLng = newLng {
                viewModel.handleLocationChange(latitude: locationManager.latitude, longitude: newLng)
            }
        }
    }
}

#Preview {
    ContentView()
}
