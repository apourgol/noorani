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

}

#Preview {
    NotificationsView(prayerFetcher: PrayerTimesFetcher())
}
