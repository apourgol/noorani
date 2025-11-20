//
//  ContentView.swift
//  Noorani
//
//  Copyright © 2025 AP Bros. All rights reserved.

import SwiftUI

struct ContentView: View {
    @ObservedObject var fetcher: PrayerTimesFetcher
    @ObservedObject var locationManager: LocationManager
    @StateObject private var viewModel: ContentViewModel
    @Environment(\.scenePhase) private var scenePhase
    @State private var lastRefreshDate: Date = Date()

    // Custom initializer - accepts preloaded instances from SplashScreen
    init(prayerFetcher: PrayerTimesFetcher? = nil, locationManager: LocationManager? = nil) {
        // Use provided instances or create new ones (for Preview)
        let fetcher = prayerFetcher ?? PrayerTimesFetcher()
        let locMgr = locationManager ?? LocationManager()

        self.fetcher = fetcher
        self.locationManager = locMgr
        self._viewModel = StateObject(wrappedValue: ContentViewModel(
            prayerTimesFetcher: fetcher,
            locationManager: locMgr
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
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                // Check if user has "current location" mode enabled
                let useCurrentLocation = UserDefaults.standard.bool(forKey: "useCurrentLocation")

                // Only auto-refresh if "current location" mode is active
                if useCurrentLocation {
                    let timeSinceLastRefresh = Date().timeIntervalSince(lastRefreshDate)

                    // Only refresh if more than 1 minute has passed (avoid duplicate refreshes)
                    if timeSinceLastRefresh > 60 {
                        print("🔄 App became active with current location mode, refreshing...")
                        lastRefreshDate = Date()

                        // Request fresh location - coordinates will be updated via onChange handlers
                        locationManager.requestLocation {
                            print("📍 Auto-refresh: Location request completed")
                        }
                    }
                }
            }
        }
        .onChange(of: locationManager.isLoading) { oldValue, newValue in
            // Trigger when location loading completes (goes from true to false)
            if oldValue && !newValue {
                print("📍 Location loading completed, checking for coordinates...")
                if let lat = locationManager.latitude, let lng = locationManager.longitude {
                    print("📍 Valid coordinates received: \(lat), \(lng)")
                    viewModel.handleLocationChange(latitude: lat, longitude: lng)
                } else {
                    print("⚠️ Location loading completed but coordinates are nil")
                }
            }
        }
        .onChange(of: locationManager.latitude) { oldValue, newValue in
            // Watch for manual city selection (coordinates change without isLoading)
            if let lat = newValue, let lng = locationManager.longitude {
                print("📍 ContentView: Latitude changed to \(lat), updating prayer times...")
                viewModel.handleLocationChange(latitude: lat, longitude: lng)
            }
        }
        .onChange(of: locationManager.longitude) { oldValue, newValue in
            // Watch for manual city selection (coordinates change without isLoading)
            if let lat = locationManager.latitude, let lng = newValue {
                print("📍 ContentView: Longitude changed to \(lng), updating prayer times...")
                viewModel.handleLocationChange(latitude: lat, longitude: lng)
            }
        }
    }
}

#Preview {
    ContentView()
}
