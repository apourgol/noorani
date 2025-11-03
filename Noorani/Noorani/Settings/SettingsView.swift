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
    @State private var showingCalculationView = false
    @State private var showingCalendarView = false
    @State private var showingNotificationsView = false
    @State private var showingAboutView = false
    @State private var showingResetAlert = false

    var body: some View {
        NavigationView {
            ZStack {
                // Same gradient as home screen
                LinearGradient(
                    colors: [
                        Color(hex: "#fab555"),
                        Color(hex: "#feecd3"),
                        Color.white
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea(.all, edges: .vertical)

                VStack(alignment: .leading, spacing: 0) {
                    // Header
                    HStack {
                        Text("Settings")
                            .font(.custom("Nunito-Regular", size: 32))
                            .fontWeight(.bold)
                            .foregroundColor(.black)

                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                    ScrollView {
                        VStack(spacing: 0) {
                            // Settings Container
                            VStack(spacing: 0) {
                                // Prayer Time Calculation
                                SettingsRow(
                                    title: "Prayer Time Calculation",
                                    subtitle: "Choose method, time format & optional prayers",
                                    showChevron: true,
                                    action: {
                                        showingCalculationView = true
                                    }
                                )
                                
                                Divider()
                                    .background(Color.gray.opacity(0.2))
                                
                                // Calendar Setting
                                SettingsRow(
                                    title: "Calendar Setting",
                                    subtitle: "Hijri and Gregorian options",
                                    showChevron: true,
                                    action: {
                                        showingCalendarView = true
                                    }
                                )
                                
                                Divider()
                                    .background(Color.gray.opacity(0.2))
                                
                                // Notifications
                                SettingsRow(
                                    title: "Notifications",
                                    subtitle: "Customize prayer time alerts",
                                    showChevron: true,
                                    action: {
                                        showingNotificationsView = true
                                    }
                                )
                                
                                Divider()
                                    .background(Color.gray.opacity(0.2))
                                
                                // About
                                SettingsRow(
                                    title: "About",
                                    subtitle: "App info and support",
                                    showChevron: true,
                                    action: {
                                        showingAboutView = true
                                    }
                                )
                                
                                Divider()
                                    .background(Color.gray.opacity(0.2))
                                
                                // Reset to Default Settings
                                SettingsRow(
                                    title: "Reset to Default Settings",
                                    subtitle: "Restore all settings to default",
                                    showChevron: false,
                                    isDestructive: true,
                                    action: {
                                        showingResetAlert = true
                                    }
                                )
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white)
                                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
                            )
                            .padding(.horizontal, 20)
                            .padding(.top, 30)
                        }
                    }

                    Spacer()
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingCalculationView) {
            PrayerTimeCalculationView(prayerFetcher: prayerFetcher)
        }
        .sheet(isPresented: $showingCalendarView) {
            CalendarSettingView()
        }
        .sheet(isPresented: $showingNotificationsView) {
            NotificationsView()
        }
        .sheet(isPresented: $showingAboutView) {
            AboutView()
        }
        .alert("Reset Settings", isPresented: $showingResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                resetToDefaultSettings()
            }
        } message: {
            Text("Are you sure you want to reset all settings to their default values? This action cannot be undone.")
        }
    }
    
    private func resetToDefaultSettings() {
        // Reset all UserDefaults/AppStorage values to defaults
        UserDefaults.standard.removeObject(forKey: "timeFormat")
        UserDefaults.standard.removeObject(forKey: "selectedCalculationMethod")
        UserDefaults.standard.removeObject(forKey: "notificationsEnabled")
        UserDefaults.standard.removeObject(forKey: "calendarType")
        UserDefaults.standard.removeObject(forKey: "currentCity")
        // Add other settings keys as needed
        
        // Notify prayer fetcher to reset to defaults
        prayerFetcher.resetToDefaults()
    }
}

struct SettingsRow: View {
    let title: String
    let subtitle: String
    let showChevron: Bool
    var isDestructive: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.custom("Nunito-Regular", size: 17))
                        .fontWeight(.regular)
                        .foregroundColor(isDestructive ? .red : .black)
                        .multilineTextAlignment(.leading)

                    Text(subtitle)
                        .font(.custom("Nunito-Regular", size: 15))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                if showChevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color.orange.opacity(0.8))
                } else if isDestructive {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.red.opacity(0.7))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    SettingsView(prayerFetcher: PrayerTimesFetcher())
}
