//
//  NotificationsView.swift
//  Noorani
//  Copyright © 2025 AP Bros. All rights reserved.


//

import SwiftUI
import UserNotifications

struct NotificationsView: View {
    @ObservedObject var prayerFetcher: PrayerTimesFetcher
    @StateObject private var viewModel = NotificationsViewModel()
    @Environment(\.dismiss) private var dismiss
    // LIVE ACTIVITIES DISABLED
    // @State private var showingLiveActivityPreview = false

    // Expansion state for per-prayer detail views
    @State private var fajrExpanded = false
    @State private var dhuhrExpanded = false
    @State private var asrExpanded = false
    @State private var maghribExpanded = false
    @State private var ishaExpanded = false

    var body: some View {
        ZStack {
            // Same gradient as home screen
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

            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.white)
                            .font(.system(size: 18, weight: .medium))
                    }

                    Text("Notifications")
                        .font(.custom("Nunito-Regular", size: 24))
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                        .padding(.leading, 10)

                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        // MARK: - NOTIFICATIONS SECTION
                        VStack(alignment: .leading, spacing: 0) {
                            // Master toggle
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Enable Notifications")
                                        .font(.custom("Nunito-Regular", size: 16))
                                        .foregroundColor(.black)

                                    Text("Receive prayer time alerts")
                                        .font(.custom("Nunito-Light", size: 14))
                                        .foregroundColor(.black.opacity(0.6))
                                }

                                Spacer()

                                Toggle("", isOn: Binding(
                                    get: { viewModel.notificationsEnabled },
                                    set: { _ in viewModel.toggleNotifications() }
                                ))
                                .tint(Color(hex: "#fab555"))
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 20)

                            if viewModel.notificationsEnabled {
                                // Per-prayer notification detail views
                                prayerNotificationsSection
                            }
                        }

                        // LIVE ACTIVITIES DISABLED - Keeping local notifications only
                        // Divider between Notifications and Live Activities
                        // Divider()
                        //     .frame(height: 2)
                        //     .background(Color.gray.opacity(0.2))
                        //     .padding(.horizontal, 20)
                        //     .padding(.vertical, 30)

                        // MARK: - LIVE ACTIVITIES SECTION (COMMENTED OUT)
                        // liveActivitiesSection
                    }
                }

                Spacer()
            }
        }
        .navigationBarHidden(true)
        .gesture(
            DragGesture()
                .onEnded { gesture in
                    if gesture.translation.width > 100 && abs(gesture.translation.height) < 50 {
                        dismiss()
                    }
                }
        )
        .onAppear {
            // Link ViewModel to PrayerTimesFetcher for rescheduling
            viewModel.prayerTimesFetcher = prayerFetcher
            viewModel.checkNotificationPermission()
            viewModel.updatePendingNotificationsCount()
        }
        .alert("Notification Permission", isPresented: $viewModel.showingPermissionAlert) {
            Button("Settings") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Please enable notifications in Settings to receive prayer time alerts.")
        }
        // LIVE ACTIVITIES DISABLED
        // .sheet(isPresented: $showingLiveActivityPreview) {
        //     LiveActivityPreviewView()
        // }
    }

    // MARK: - Prayer Notifications Section
    private var prayerNotificationsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Prayer Notifications")
                .font(.custom("Nunito-SemiBold", size: 18))
                .foregroundColor(.black.opacity(0.8))
                .padding(.horizontal, 20)
                .padding(.top, 30)

            Text("Tap each prayer to customize notification timing")
                .font(.custom("Nunito-Light", size: 14))
                .foregroundColor(.black.opacity(0.6))
                .padding(.horizontal, 20)
                .padding(.top, 4)

            VStack(spacing: 0) {
                PrayerDetailRowView(
                    prayerName: "Fajr",
                    viewModel: viewModel,
                    isExpanded: $fajrExpanded
                )
                Divider().background(Color.gray.opacity(0.3))

                PrayerDetailRowView(
                    prayerName: "Dhuhr",
                    viewModel: viewModel,
                    isExpanded: $dhuhrExpanded
                )
                Divider().background(Color.gray.opacity(0.3))

                if prayerFetcher.showAsr {
                    PrayerDetailRowView(
                        prayerName: "Asr",
                        viewModel: viewModel,
                        isExpanded: $asrExpanded
                    )
                    Divider().background(Color.gray.opacity(0.3))
                }

                PrayerDetailRowView(
                    prayerName: "Maghrib",
                    viewModel: viewModel,
                    isExpanded: $maghribExpanded
                )

                if prayerFetcher.showIsha {
                    Divider().background(Color.gray.opacity(0.3))

                    PrayerDetailRowView(
                        prayerName: "Isha",
                        viewModel: viewModel,
                        isExpanded: $ishaExpanded
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
        }
    }

    // MARK: - Live Activities Section (DISABLED - LOCAL NOTIFICATIONS ONLY)
    /*
    private var liveActivitiesSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Live Activities")
                .font(.custom("Nunito-SemiBold", size: 18))
                .foregroundColor(.black.opacity(0.8))
                .padding(.horizontal, 20)
                .padding(.top, 30)

            // Live Activity info
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "timer")
                    .foregroundColor(Color(hex: "#fab555"))
                    .font(.system(size: 24))

                VStack(alignment: .leading, spacing: 4) {
                    Text("Prayer Countdown on Lock Screen")
                        .font(.custom("Nunito-Regular", size: 16))
                        .foregroundColor(.black)

                    Text("Shows a live countdown timer on your Lock Screen and Dynamic Island before each prayer")
                        .font(.custom("Nunito-Light", size: 14))
                        .foregroundColor(.black.opacity(0.6))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)

            // Enable toggle
            HStack {
                Text("Enable Live Activities")
                    .font(.custom("Nunito-Regular", size: 16))
                    .foregroundColor(.black)

                Spacer()

                Toggle("", isOn: Binding(
                    get: { viewModel.liveActivitiesEnabled },
                    set: { _ in viewModel.toggleLiveActivities() }
                ))
                .tint(Color(hex: "#fab555"))
            }
            .padding(.horizontal, 20)
            .padding(.top, 15)

            // Preview button
            Button(action: { showingLiveActivityPreview = true }) {
                HStack {
                    Image(systemName: "eye.fill")
                        .font(.system(size: 16))
                    Text("Preview Live Activity Designs")
                        .font(.custom("Nunito-Regular", size: 14))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(hex: "#fab555"))
                .clipShape(Capsule())
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)

            if viewModel.liveActivitiesEnabled {
                // Per-prayer Live Activity toggles
                VStack(alignment: .leading, spacing: 0) {
                    Text("Activate Live Activities for Prayers")
                        .font(.custom("Nunito-SemiBold", size: 16))
                        .foregroundColor(.black.opacity(0.8))
                        .padding(.horizontal, 20)
                        .padding(.top, 20)

                    Text("Choose which prayers show Live Activities")
                        .font(.custom("Nunito-Light", size: 14))
                        .foregroundColor(.black.opacity(0.6))
                        .padding(.horizontal, 20)
                        .padding(.top, 4)

                    VStack(spacing: 1) {
                        NotificationToggleRow(
                            title: "Fajr",
                            isOn: Binding(
                                get: { viewModel.fajrLiveActivity },
                                set: { viewModel.updatePrayerLiveActivity(prayer: "fajr", enabled: $0) }
                            )
                        )
                        Divider().background(Color.gray.opacity(0.3))

                        NotificationToggleRow(
                            title: "Dhuhr",
                            isOn: Binding(
                                get: { viewModel.dhuhrLiveActivity },
                                set: { viewModel.updatePrayerLiveActivity(prayer: "dhuhr", enabled: $0) }
                            )
                        )
                        Divider().background(Color.gray.opacity(0.3))

                        if prayerFetcher.showAsr {
                            NotificationToggleRow(
                                title: "Asr",
                                isOn: Binding(
                                    get: { viewModel.asrLiveActivity },
                                    set: { viewModel.updatePrayerLiveActivity(prayer: "asr", enabled: $0) }
                                )
                            )
                            Divider().background(Color.gray.opacity(0.3))
                        }

                        NotificationToggleRow(
                            title: "Maghrib",
                            isOn: Binding(
                                get: { viewModel.maghribLiveActivity },
                                set: { viewModel.updatePrayerLiveActivity(prayer: "maghrib", enabled: $0) }
                            )
                        )
                        Divider().background(Color.gray.opacity(0.3))

                        if prayerFetcher.showIsha {
                            NotificationToggleRow(
                                title: "Isha",
                                isOn: Binding(
                                    get: { viewModel.ishaLiveActivity },
                                    set: { viewModel.updatePrayerLiveActivity(prayer: "isha", enabled: $0) }
                                )
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                }

                // Start offset
                HStack {
                    Text("Start countdown before prayer")
                        .font(.custom("Nunito-Regular", size: 16))
                        .foregroundColor(.black)

                    Spacer()

                    HStack(spacing: 15) {
                        Button(action: {
                            // Decrement by 5 for fine control
                            viewModel.updateLiveActivityStartOffset(max(5, viewModel.liveActivityStartOffset - 5))
                        }) {
                            Image(systemName: "minus.circle")
                                .foregroundColor(viewModel.liveActivityStartOffset <= 5 ? Color.gray.opacity(0.3) : Color(hex: "#fab555"))
                                .font(.system(size: 24))
                        }
                        .disabled(viewModel.liveActivityStartOffset <= 5)

                        Text("\(viewModel.liveActivityStartOffset)m")
                            .font(.custom("Nunito-SemiBold", size: 16))
                            .foregroundColor(.black)
                            .frame(minWidth: 50)

                        Button(action: {
                            // Increment by 5 for fine control, max 180 minutes (3 hours)
                            viewModel.updateLiveActivityStartOffset(min(180, viewModel.liveActivityStartOffset + 5))
                        }) {
                            Image(systemName: "plus.circle")
                                .foregroundColor(viewModel.liveActivityStartOffset >= 180 ? Color.gray.opacity(0.3) : Color(hex: "#fab555"))
                                .font(.system(size: 24))
                        }
                        .disabled(viewModel.liveActivityStartOffset >= 180)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)

                // iOS version note
                if #available(iOS 16.2, *) {
                    // Live Activities available
                } else {
                    Text("Live Activities require iOS 16.2 or later")
                        .font(.custom("Nunito-Light", size: 12))
                        .foregroundColor(.red.opacity(0.8))
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                }
            }
        }
        .padding(.bottom, 40)
    }
    */
}

// MARK: - NotificationToggleRow (DISABLED - Only used by Live Activities)
/*
struct NotificationToggleRow: View {
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        HStack {
            Text(title)
                .font(.custom("Nunito-Regular", size: 16))
                .foregroundColor(.black)

            Spacer()

            Toggle("", isOn: $isOn)
                .tint(Color(hex: "#fab555"))
        }
        .padding(.vertical, 16)
    }
}
*/

#Preview {
    NotificationsView(prayerFetcher: PrayerTimesFetcher())
}
