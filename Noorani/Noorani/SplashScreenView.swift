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

                VStack(spacing: 16) {
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
                }
                .opacity(opacity)
            }
            .onAppear {
                // Preload prayer times data during splash screen
                print("🚀 SplashScreen: Preloading prayer times...")

                // Check if user has "current location" mode enabled
                let useCurrentLocation = UserDefaults.standard.bool(forKey: "useCurrentLocation")

                if useCurrentLocation {
                    // ALWAYS request fresh location when in "current location" mode
                    // This ensures prayer times update when user travels to new location
                    print("📍 Current location mode active, requesting fresh location...")
                    locationManager.requestLocation { }
                } else {
                    // Manual city selected - only request if no coordinates exist
                    if prayerFetcher.currentLat == 0.0 || prayerFetcher.currentLng == 0.0 {
                        locationManager.requestLocation { }
                    }
                }

                // If we have cached location, trigger fetch immediately
                // (will be updated if fresh location comes in)
                if prayerFetcher.currentLat != 0.0 && prayerFetcher.currentLng != 0.0 {
                    Task {
                        await prayerFetcher.fetchPrayerTimes(
                            latitude: prayerFetcher.currentLat,
                            longitude: prayerFetcher.currentLng
                        )
                        print("✅ SplashScreen: Prayer times preloaded")
                        // Data is ready, allow transition
                        canTransition = true
                    }
                } else {
                    print("⏳ SplashScreen: No cached location, waiting for location...")
                }

                // Fade in
                withAnimation(.easeIn(duration: 1)) {
                    opacity = 1.0
                }

                // SAFETY TIMEOUT: Force transition after 10 seconds maximum
                // This prevents infinite loading if location/network fails
                DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                    if !canTransition {
                        print("⚠️ SplashScreen: Timeout reached, forcing transition")
                        canTransition = true
                    }
                }
            }
            .onChange(of: prayerFetcher.isLoading) { oldValue, newValue in
                // When prayer times finish loading (goes from true to false)
                if oldValue && !newValue && !prayerFetcher.prayerTimes.isEmpty {
                    print("✅ SplashScreen: Prayer times loaded, ready to transition")
                    canTransition = true
                }
            }
            .onChange(of: locationManager.isLoading) { oldValue, newValue in
                // When location finishes loading
                if oldValue && !newValue {
                    if let lat = locationManager.latitude, let lng = locationManager.longitude {
                        print("📍 SplashScreen: Location obtained (\(lat), \(lng)), fetching prayer times...")
                        Task {
                            await prayerFetcher.fetchPrayerTimes(latitude: lat, longitude: lng)
                        }
                    } else {
                        print("⚠️ SplashScreen: Location failed, allowing transition anyway")
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
}

#Preview {
    SplashScreenView()
}
