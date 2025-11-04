//
//  SettingsView.swift
//  Noorani
//
//  Copyright © 2025 AP Bros. All rights reserved.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var prayerFetcher: PrayerTimesFetcher
    @StateObject private var viewModel: SettingsViewModel
    
    // Custom initializer for dependency injection
    init(prayerFetcher: PrayerTimesFetcher) {
        self.prayerFetcher = prayerFetcher
        self._viewModel = StateObject(wrappedValue: SettingsViewModel(prayerTimesFetcher: prayerFetcher))
    }

    var body: some View {
        NavigationView {
            ZStack {
                // Same gradient as home screen
                LinearGradient(
                    colors: [
                        Color.nooraniPrimary,
                        Color.nooraniSecondary,
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
                                    action: viewModel.showCalculationView
                                )
                                
                                Divider()
                                    .background(Color.gray.opacity(0.2))
                                
                                // Calendar Setting
                                SettingsRow(
                                    title: "Calendar Setting",
                                    subtitle: "Hijri and Gregorian options",
                                    showChevron: true,
                                    action: viewModel.showCalendarView
                                )
                                
                                Divider()
                                    .background(Color.gray.opacity(0.2))
                                
                                // Notifications
                                SettingsRow(
                                    title: "Notifications",
                                    subtitle: "Customize prayer time alerts",
                                    showChevron: true,
                                    action: viewModel.showNotificationsView
                                )
                                
                                Divider()
                                    .background(Color.gray.opacity(0.2))
                                
                                // About
                                SettingsRow(
                                    title: "About",
                                    subtitle: "App info and support",
                                    showChevron: true,
                                    action: viewModel.showAboutView
                                )
                                
                                Divider()
                                    .background(Color.gray.opacity(0.2))
                                
                                // Reset to Default Settings
                                SettingsRow(
                                    title: "Reset to Default Settings",
                                    subtitle: "Restore all settings to default",
                                    showChevron: false,
                                    isDestructive: true,
                                    action: viewModel.showResetAlert
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
        .sheet(isPresented: $viewModel.showingCalculationView) {
            PrayerTimeCalculationView(prayerFetcher: prayerFetcher)
        }
        .sheet(isPresented: $viewModel.showingCalendarView) {
            CalendarSettingView()
        }
        .sheet(isPresented: $viewModel.showingNotificationsView) {
            NotificationsView(prayerFetcher: prayerFetcher)
        }
        .sheet(isPresented: $viewModel.showingAboutView) {
            AboutView()
        }
        .alert("Reset Settings", isPresented: $viewModel.showingResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                viewModel.resetToDefaults()
            }
        } message: {
            Text("Are you sure you want to reset all settings to their default values? This action cannot be undone.")
        }
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
                        .foregroundColor(Color.nooraniPrimary.opacity(0.8))
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
