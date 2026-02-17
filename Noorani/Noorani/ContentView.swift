//
//  ContentView.swift
//  Noorani
//
//  Copyright © 2025 AP Bros. All rights reserved.

import SwiftUI
import ActivityKit

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
                print("🔄 App became active")

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

                // Clear any previous dismissals so Live Activity can restart
                if #available(iOS 16.1, *) {
                    LiveActivityManager.shared.clearAllDismissals()
                }

                // Check and trigger Live Activity
                checkAndStartLiveActivity()
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

    // MARK: - Live Activity Trigger

    /// The 5 actual prayer times (NOT sunrise, sunset, or midnight)
    private let actualPrayers = ["Fajr", "Dhuhr", "Asr", "Maghrib", "Isha"]

    /// Find the next actual prayer (skipping sunrise, sunset, midnight)
    private func findNextActualPrayer() -> (name: String, time: Date)? {
        let now = Date()

        // Combine today and tomorrow prayer times
        var allPrayerTimes: [(name: String, time: Date)] = []

        for (name, time) in fetcher.prayerTimes where actualPrayers.contains(name) && time > now {
            allPrayerTimes.append((name: name, time: time))
        }

        for (name, time) in fetcher.tomorrowPrayerTimes where actualPrayers.contains(name) && time > now {
            allPrayerTimes.append((name: name, time: time))
        }

        // Sort by time and return the earliest
        return allPrayerTimes.sorted { $0.time < $1.time }.first
    }

    private func checkAndStartLiveActivity() {
        print("🔍 [Live Activity] Checking if should start...")

        guard #available(iOS 16.1, *) else {
            print("❌ [Live Activity] iOS version too old")
            return
        }

        // Find the next actual prayer (Fajr, Dhuhr, Asr, Maghrib, Isha only)
        guard let nextPrayer = findNextActualPrayer() else {
            print("❌ [Live Activity] No upcoming prayer found")
            return
        }

        let nextPrayerName = nextPrayer.name
        let nextPrayerTime = nextPrayer.time

        print("📝 [Live Activity] Next prayer: \(nextPrayerName) at \(nextPrayerTime)")

        // Save prayer info to SharedDataManager for background access
        let icon = iconForPrayer(nextPrayerName)
        SharedDataManager.shared.saveNextPrayerInfo(
            name: nextPrayerName,
            time: nextPrayerTime,
            icon: icon
        )

        // Schedule background task for future checks
        Task { @MainActor in
            BackgroundTaskManager.shared.scheduleBackgroundTask()
        }

        // Check if Live Activities enabled (read from App Group via SharedDataManager)
        let liveActivitiesEnabled = SharedDataManager.shared.areLiveActivitiesEnabled()
        print("📝 [Live Activity] Master toggle enabled: \(liveActivitiesEnabled)")
        guard liveActivitiesEnabled else {
            print("❌ [Live Activity] Master toggle is OFF")
            return
        }

        // Check if this prayer has Live Activity enabled (read from App Group)
        let prayerEnabled = SharedDataManager.shared.isPrayerLiveActivityEnabled(prayer: nextPrayerName)
        print("📝 [Live Activity] \(nextPrayerName) enabled: \(prayerEnabled)")
        guard prayerEnabled else {
            print("❌ [Live Activity] \(nextPrayerName) is disabled")
            return
        }

        // Get configured time offset for this prayer (read from App Group)
        let offsetMinutes = SharedDataManager.shared.getPrayerLiveActivityOffset(prayer: nextPrayerName)
        print("📝 [Live Activity] Time window: \(offsetMinutes) minutes")

        // Calculate time until prayer
        let timeUntilPrayer = nextPrayerTime.timeIntervalSince(Date())
        let offsetSeconds = TimeInterval(offsetMinutes * 60)
        let minutesUntilPrayer = Int(timeUntilPrayer / 60)

        print("📝 [Live Activity] Time until prayer: \(minutesUntilPrayer) minutes (window: \(offsetMinutes) minutes)")

        // Check if within time window
        if timeUntilPrayer > 0 && timeUntilPrayer <= offsetSeconds {
            print("✅ [Live Activity] WITHIN WINDOW - Starting Live Activity for \(nextPrayerName)")
            LiveActivityManager.shared.startLiveActivity(
                for: nextPrayerName,
                targetTime: nextPrayerTime
            )
        } else {
            print("⏭️ [Live Activity] NOT within window - Need to be within \(offsetMinutes)m, currently \(minutesUntilPrayer)m away")
        }
    }

    private func iconForPrayer(_ prayer: String) -> String {
        switch prayer {
        case "Fajr": return "sunrise.fill"
        case "Dhuhr": return "sun.max.fill"
        case "Asr": return "sun.min.fill"
        case "Maghrib": return "moon.fill"
        case "Isha": return "moon.stars.fill"
        default: return "clock.fill"
        }
    }
}

#Preview {
    ContentView()
}
