//
//  SettingsView.swift
//  Noorani
//
//  Created by Amin Pourgol on 10/20/25.
//  Copyright © 2025 AP Bros. All rights reserved.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var prayerFetcher: PrayerTimesFetcher
    @State private var navigationPath = NavigationPath()
    
    // AppStorage properties for reset functionality
    @AppStorage("calculationMethod") private var calculationMethod: Int = 7
    @AppStorage("calendarType") private var calendarType: String = "both"
    @AppStorage("hijriOffset") private var hijriOffset: Int = 0
    @AppStorage("madhab") private var madhab: String = "shia"
    @AppStorage("timeFormat") private var timeFormat: String = "12"
    @AppStorage("locationAutoUpdate") private var locationAutoUpdate: Bool = true
    
    private func resetAllSettings() {
        calculationMethod = 7
        calendarType = "both"
        hijriOffset = 0
        madhab = "shia"
        timeFormat = "12"
        locationAutoUpdate = true
        
        // You might want to add additional reset logic here
        // such as clearing notification settings, etc.
    }
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color(hex: "#fab555"), location: 0.0),
                        .init(color: Color(hex: "#feecd3"), location: 0.45),
                        .init(color: Color.white.opacity(0.95), location: 0.75),
                        .init(color: Color.white, location: 1.0)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea(.all, edges: .vertical)
                
                VStack(alignment: .leading, spacing: 0) {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Settings")
                            .font(.custom("Nunito-Regular", size: 36))
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                            .padding(.leading, 0)
                    }
                    .padding(.horizontal, 25)
                    .padding(.top, 60) // More top padding for main settings
                    
                    ScrollView {
                        VStack(spacing: 30) {
                            VStack(spacing: 0) {
                                MainSettingsRow(
                                    title: "Prayer Time Calculation",
                                    subtitle: "Choose calculation method",
                                    isFirst: true
                                ) {
                                    navigationPath.append("PrayerTimeCalculation")
                                }
                                
                                MainSettingsDivider()
                                
                                // Calendar Setting
                                MainSettingsRow(
                                    title: "Calendar Setting",
                                    subtitle: "Hijri and Gregorian options"
                                ) {
                                    navigationPath.append("CalendarSetting")
                                }
                                
                                MainSettingsDivider()
                                
                                // Notifications
                                MainSettingsRow(
                                    title: "Notifications",
                                    subtitle: "Customize prayer time alerts"
                                ) {
                                    navigationPath.append("Notifications")
                                }
                                
                                MainSettingsDivider()
                                
                                // About
                                MainSettingsRow(
                                    title: "About",
                                    subtitle: "App info and support"
                                ) {
                                    navigationPath.append("About")
                                }
                                
                                MainSettingsDivider()
                                
                                // Reset to Default Settings
                                MainSettingsRow(
                                    title: "Reset to Default Settings",
                                    subtitle: "Restore all settings to default",
                                    isLast: true,
                                    isDestructive: true
                                ) {
                                    resetAllSettings()
                                }
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.white)
                                    .shadow(color: Color.black.opacity(0.08), radius: 20, x: 0, y: 8)
                            )
                            .padding(.horizontal, 20)
                            .padding(.top, 35)
                        }
                    }
                    
                    Spacer(minLength: 100) // Extra space at bottom
                }
            }
            .navigationDestination(for: String.self) { destination in
                switch destination {
                case "PrayerTimeCalculation":
                    PrayerTimeCalculationView(prayerFetcher: prayerFetcher)
                case "CalendarSetting":
                    CalendarSettingView()
                case "Notifications":
                    NotificationsView()
                case "About":
                    AboutView()
                default:
                    EmptyView()
                }
            }
        }
    }
}

// Beautiful Main Settings Row Component - with Button for proper text colors
struct MainSettingsRow: View {
    let title: String
    let subtitle: String
    let isFirst: Bool
    let isLast: Bool
    let isDestructive: Bool
    let action: () -> Void
    
    init(title: String, subtitle: String, isFirst: Bool = false, isLast: Bool = false, isDestructive: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.subtitle = subtitle
        self.isFirst = isFirst
        self.isLast = isLast
        self.isDestructive = isDestructive
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.custom("Nunito-Regular", size: 17))
                        .fontWeight(.medium)
                        .foregroundColor(isDestructive ? .red : .black) // Red for destructive actions
                    
                    Text(subtitle)
                        .font(.custom("Nunito-Regular", size: 15))
                        .fontWeight(.regular)
                        .foregroundColor(.black.opacity(0.6))
                }
                
                Spacer()
                
                Image(systemName: isDestructive ? "exclamationmark.triangle" : "chevron.right")
                    .foregroundColor(isDestructive ? .red : Color(hex: "#fab555")) // Red icon for destructive actions
                    .font(.system(size: 14, weight: .semibold))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .contentShape(Rectangle()) // Makes entire row tappable
        }
        .buttonStyle(PlainButtonStyle()) // Removes button styling
    }
}

// Beautiful Divider Component - matching MoreSettings style
struct MainSettingsDivider: View {
    var body: some View {
        Divider()
            .background(Color.gray.opacity(0.15))
            .padding(.leading, 20)
    }
}

#Preview {
    NavigationView {
        SettingsView(prayerFetcher: PrayerTimesFetcher())
    }
}
