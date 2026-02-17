//
//  SplashScreenView.swift
//  Noorani
//  Copyright © 2025 AP Bros. All rights reserved.


//

import SwiftUI

struct SplashScreenView: View {
    @State private var isActive = false
    @State private var opacity = 0.0
    @State private var canTransition = false // NEW: Track if we're ready to transition
    @StateObject private var prayerFetcher = PrayerTimesFetcher()
    @StateObject private var locationManager = LocationManager()

    var body: some View {
        if isActive {
            ContentView(prayerFetcher: prayerFetcher, locationManager: locationManager)
                .transition(.opacity)
        } else {
            ZStack {
                // App's signature gradient background
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color(hex: "#fab555"), location: 0.0),
                        .init(color: Color(hex: "#feecd3"), location: 0.55),
                        .init(color: Color.white, location: 1.0)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 20) {
                    // Logo
                    Image("splash")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)

                    // App name
                    Text("Noorani")
                        .font(.system(size: 32, weight: .light, design: .serif))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(hex: "#d4892e"),
                                    Color(hex: "#fab555")
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )

                    // Loading indicator - only show if still loading
                    if !canTransition {
                        VStack(spacing: 8) {
                            ProgressView()
                                .tint(Color(hex: "#d4892e"))
                                .scaleEffect(0.8)

                            Text(prayerFetcher.isLoading ? "Loading prayer times..." : "Getting location...")
                                .font(.custom("Nunito-Regular", size: 14))
                                .foregroundColor(Color(hex: "#d4892e").opacity(0.8))
                        }
                        .padding(.top, 8)
                    }
                }
                .opacity(opacity)
            }
            .onAppear {
                // Preload prayer times data during splash screen
                print("🚀 SplashScreen: Preloading prayer times...")

                // Check if this is first launch
                let isFirstLaunch = prayerFetcher.currentLat == 0.0 && prayerFetcher.currentLng == 0.0 && prayerFetcher.prayerTimes.isEmpty

                // Check if user has "current location" mode enabled
                let useCurrentLocation = UserDefaults.standard.bool(forKey: "useCurrentLocation")

                if useCurrentLocation || isFirstLaunch {
                    // ALWAYS request fresh location when in "current location" mode OR first launch
                    // This ensures prayer times update when user travels to new location
                    print("📍 \(isFirstLaunch ? "First launch" : "Current location mode") - requesting fresh location...")
                    locationManager.requestLocation { }
                } else {
                    // Manual city selected - only request if no coordinates exist
                    if prayerFetcher.currentLat == 0.0 || prayerFetcher.currentLng == 0.0 {
                        print("📍 No coordinates, requesting location...")
                        locationManager.requestLocation { }
                    }
                }

                // If we have cached location, trigger fetch immediately
                // (will be updated if fresh location comes in)
                if prayerFetcher.currentLat != 0.0 && prayerFetcher.currentLng != 0.0 {
                    // If we already have cached prayer times, allow immediate transition
                    if !prayerFetcher.prayerTimes.isEmpty {
                        print("✅ SplashScreen: Cached prayer times available, ready for immediate transition")
                        canTransition = true
                    }

                    // Still fetch fresh data in background
                    Task {
                        await prayerFetcher.fetchPrayerTimes(
                            latitude: prayerFetcher.currentLat,
                            longitude: prayerFetcher.currentLng
                        )
                        print("✅ SplashScreen: Prayer times fetch completed")
                        // Data is ready, allow transition if not already allowed
                        if !canTransition {
                            canTransition = true
                        }
                    }
                } else {
                    print("⏳ SplashScreen: No cached location, waiting for location...")
                }

                // Fade in
                withAnimation(.easeIn(duration: 1)) {
                    opacity = 1.0
                }

                // SAFETY TIMEOUT: Force transition after 15 seconds maximum (increased for first launch)
                // This prevents infinite loading if location/network fails
                // BUT only if we have SOME data (either cached or fetched)
                DispatchQueue.main.asyncAfter(deadline: .now() + 15) {
                    if !canTransition {
                        print("⚠️ SplashScreen: Timeout reached after 15s")

                        // Check if we got ANY prayer times during the wait
                        if !prayerFetcher.prayerTimes.isEmpty {
                            print("✅ SplashScreen: We have prayer times, allowing transition")
                            canTransition = true
                        } else {
                            print("❌ SplashScreen: No prayer times yet, forcing transition anyway")
                            canTransition = true
                        }
                    }
                }
            }
            .onChange(of: prayerFetcher.isLoading) { oldValue, newValue in
                // When prayer times finish loading (goes from true to false)
                if oldValue && !newValue && !prayerFetcher.prayerTimes.isEmpty {
                    print("✅ SplashScreen: Prayer times loaded, ready to transition")
                    canTransition = true

                    // Check and trigger Live Activity on initial launch
                    if #available(iOS 16.1, *) {
                        checkAndStartLiveActivityOnLaunch()
                    }
                }
            }
            .onChange(of: locationManager.isLoading) { oldValue, newValue in
                // When location finishes loading
                if oldValue && !newValue {
                    if let lat = locationManager.latitude, let lng = locationManager.longitude {
                        print("📍 SplashScreen: Location obtained (\(lat), \(lng)), fetching prayer times...")
                        Task {
                            await prayerFetcher.fetchPrayerTimes(latitude: lat, longitude: lng)
                            print("✅ SplashScreen: Prayer times fetch after location completed")

                            // Check if we got prayer times
                            if !prayerFetcher.prayerTimes.isEmpty {
                                print("✅ SplashScreen: Prayer times available, allowing transition")
                                canTransition = true
                            } else {
                                print("⚠️ SplashScreen: Fetch completed but no prayer times, allowing transition anyway")
                                canTransition = true
                            }
                        }
                    } else {
                        print("⚠️ SplashScreen: Location failed or denied, allowing transition anyway")
                        canTransition = true
                    }
                }
            }
            .onChange(of: canTransition) { _, newValue in
                // When we're ready to transition, do the fade out animation
                if newValue {
                    // Wait minimum 1.5 seconds for nice animation
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation(.easeOut(duration: 1)) {
                            opacity = 0.0
                        }
                        // Transition after fade completes
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            isActive = true
                        }
                    }
                }
            }
        }
    }

    // MARK: - Live Activity Trigger

    @available(iOS 16.1, *)
    private func checkAndStartLiveActivityOnLaunch() {
        // Get next prayer info
        let nextPrayerName = prayerFetcher.nextPrayerName
        guard let nextPrayerTime = prayerFetcher.nextPrayerTime else { return }

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

        // Check if Live Activities enabled
        guard UserDefaults.standard.bool(forKey: "liveActivitiesEnabled") else { return }

        // Check if this prayer has Live Activity enabled
        let prayerKey = "\(nextPrayerName.lowercased())LiveActivity"
        guard UserDefaults.standard.object(forKey: prayerKey) as? Bool ?? true else { return }

        // Get configured time offset for this prayer
        let offsetKey = "\(nextPrayerName.lowercased())LiveActivityOffset"
        let offsetMinutes = UserDefaults.standard.object(forKey: offsetKey) as? Int ?? 30

        // Calculate time until prayer
        let timeUntilPrayer = nextPrayerTime.timeIntervalSince(Date())
        let offsetSeconds = TimeInterval(offsetMinutes * 60)

        // Check if within time window
        if timeUntilPrayer > 0 && timeUntilPrayer <= offsetSeconds {
            print("✅ [Launch] Starting Live Activity for \(nextPrayerName)")
            LiveActivityManager.shared.startLiveActivity(
                for: nextPrayerName,
                targetTime: nextPrayerTime
            )
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
    SplashScreenView()
}
