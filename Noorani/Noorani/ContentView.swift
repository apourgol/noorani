//
//  ContentView.swift
//  Noorani
//
//  Created by Amin Pourgol on 9/14/25.
//  Copyright © 2025 AP Bros. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    @StateObject var fetcher = PrayerTimesFetcher()
    @State private var selectedTab = 0
    
    var body: some View {
        if #available(iOS 18.0, *) {
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
                            TopSectionView(prayerFetcher: fetcher)
                            AzanTimesView(fetcher: fetcher)
                        }
                    }
                    .tag(0)
                }
                
                Tab("Calendar", systemImage: "calendar") {
                    VStack {
                        Text("Calendar View")
                    }
                    .tag(1)
                }
                
                Tab("Qibla", systemImage: "cube.fill") {
                    VStack {
                        Text("QiblaFinder View")
                    }
                    .tag(1)
                }
                
                Tab("Settings", systemImage: "gearshape") {
                    SettingsView(prayerFetcher: fetcher)
                        .tag(3)
                }
            }
            .tint(Color(hex: "#fab555")) // TODO: We should be adding the colors as assets
        } else {
            TabView(selection: $selectedTab) {
                ZStack(alignment: .top) {
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: Color(hex: "#fab555"), location: 0.0),
                            .init(color: Color(hex: "#feecd3"), location: 0.55),
                            .init(color: Color.white, location: 1.0)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea(.all, edges: .vertical)

                    VStack {
                        TopSectionView(prayerFetcher: fetcher)
                        AzanTimesView(fetcher: fetcher)
                    }
                }
                .tabItem {
                    Label("Prayer Times", systemImage: "sun.max")
                }
                .tag(0)

                VStack {
                    Text("Calendar View")
                }
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }
                .tag(1)
                
                VStack {
                    Text("QiblaFinder View")
                }
                .tabItem {
                    Label("Qibla", systemImage: "cube.fill")
                }
                .tag(2)

                VStack {
                    SettingsView(prayerFetcher: fetcher)
                }
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(3)
            }
            .tint(Color(hex: "#fab555")) // TODO: We should be adding the colors as assets
        }
    }
}

#Preview {
    ContentView()
}
