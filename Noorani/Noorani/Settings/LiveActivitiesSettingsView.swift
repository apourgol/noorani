//
//  LiveActivitiesSettingsView.swift
//  Noorani
//  Copyright © 2025 AP Bros. All rights reserved.
//

import SwiftUI
import ActivityKit

@available(iOS 16.1, *)
struct LiveActivitiesSettingsView: View {
    @ObservedObject var prayerFetcher: PrayerTimesFetcher
    @StateObject private var viewModel = NotificationsViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showingPreview = false

    var body: some View {
        ZStack {
            // Beautiful Noorani gradient background
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
                // MARK: - Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.white)
                            .font(.system(size: 18, weight: .medium))
                    }

                    Text("Live Activities")
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
                        // MARK: - Info Card
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 12) {
                                Image(systemName: "timer")
                                    .font(.system(size: 28))
                                    .foregroundColor(Color(hex: "#fab555"))

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Prayer Countdown on Lock Screen")
                                        .font(.custom("Nunito-SemiBold", size: 18))
                                        .foregroundColor(.black)

                                    Text("Shows a live countdown timer on your Lock Screen and Dynamic Island before each prayer")
                                        .font(.custom("Nunito-Regular", size: 14))
                                        .foregroundColor(.gray)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }

                            // Preview button
                            Button(action: { showingPreview = true }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "eye.fill")
                                        .font(.system(size: 16))
                                    Text("Preview Designs")
                                        .font(.custom("Nunito-SemiBold", size: 15))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color(hex: "#fab555"))
                                .cornerRadius(12)
                            }
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white)
                                .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
                        )
                        .padding(.horizontal, 20)
                        .padding(.top, 20)

                        // MARK: - Master Toggle Card
                        VStack(spacing: 0) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Enable Live Activities")
                                        .font(.custom("Nunito-SemiBold", size: 17))
                                        .foregroundColor(.black)

                                    Text("Show countdown on lock screen")
                                        .font(.custom("Nunito-Regular", size: 14))
                                        .foregroundColor(.gray)
                                }

                                Spacer()

                                Toggle("", isOn: Binding(
                                    get: { viewModel.liveActivitiesEnabled },
                                    set: { _ in
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            viewModel.toggleLiveActivities()
                                        }
                                    }
                                ))
                                .tint(Color(hex: "#fab555"))
                            }
                            .padding(20)

                            // Authorization status
                            if !ActivityAuthorizationInfo().areActivitiesEnabled {
                                HStack(spacing: 8) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.orange)
                                    Text("Live Activities must be enabled in Settings > Noorani")
                                        .font(.custom("Nunito-Regular", size: 13))
                                        .foregroundColor(.gray)
                                }
                                .padding(.horizontal, 20)
                                .padding(.bottom, 16)
                            }
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white)
                                .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
                        )
                        .padding(.horizontal, 20)
                        .padding(.top, 10)

                        // MARK: - Per-Prayer Settings
                        if viewModel.liveActivitiesEnabled {
                            VStack(alignment: .leading, spacing: 0) {
                                Text("PRAYER SETTINGS")
                                    .font(.custom("Nunito-Bold", size: 13))
                                    .foregroundColor(.gray)
                                    .tracking(1)
                                    .padding(.horizontal, 20)
                                    .padding(.top, 20)
                                    .padding(.bottom, 12)

                                // Info banner
                                HStack(spacing: 12) {
                                    Image(systemName: "info.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(Color(hex: "#fab555"))

                                    Text("Live Activity appears when you open the app and prayer time is within your selected window")
                                        .font(.custom("Nunito-Regular", size: 13))
                                        .foregroundColor(.gray)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .padding(16)
                                .background(Color(hex: "#fab555").opacity(0.1))
                                .cornerRadius(12)
                                .padding(.horizontal, 20)
                                .padding(.bottom, 16)

                                // Per-prayer rows
                                VStack(spacing: 1) {
                                    ForEach(["Fajr", "Dhuhr", "Asr", "Maghrib", "Isha"], id: \.self) { prayer in
                                        LiveActivityPrayerRow(
                                            prayerName: prayer,
                                            viewModel: viewModel
                                        )

                                        if prayer != "Isha" {
                                            Divider()
                                                .padding(.leading, 20)
                                        }
                                    }
                                }
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.white)
                                        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
                                )
                                .padding(.horizontal, 20)
                            }
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }

                        // Bottom spacing
                        Color.clear.frame(height: 40)
                    }
                }

                Spacer()
            }
        }
        .simultaneousGesture(
            DragGesture()
                .onEnded { gesture in
                    // Only dismiss if gesture started from left edge area (first 50 points)
                    if gesture.startLocation.x < 50 &&
                       gesture.translation.width > 80 &&
                       abs(gesture.translation.height) < 50 {
                        dismiss()
                    }
                }
        )
        .navigationBarHidden(true)
        .sheet(isPresented: $showingPreview) {
            LiveActivityPreviewView()
        }
        .onAppear {
            viewModel.prayerTimesFetcher = prayerFetcher
        }
    }
}

// MARK: - Live Activity Prayer Row
@available(iOS 16.1, *)
struct LiveActivityPrayerRow: View {
    let prayerName: String
    @ObservedObject var viewModel: NotificationsViewModel
    @State private var isExpanded: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            // Prayer row with toggle
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Text(prayerName)
                        .font(.custom("Nunito-SemiBold", size: 16))
                        .foregroundColor(.black)

                    Spacer()

                    Toggle("", isOn: Binding(
                        get: { viewModel.isLiveActivityEnabled(for: prayerName) },
                        set: { newValue in
                            viewModel.updatePrayerLiveActivity(prayerName, enabled: newValue)
                        }
                    ))
                    .tint(Color(hex: "#fab555"))

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "#d89a3d"))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())

            // Expanded time picker
            if isExpanded && viewModel.isLiveActivityEnabled(for: prayerName) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Show countdown")
                            .font(.custom("Nunito-Regular", size: 13))
                            .foregroundColor(.gray)

                        Spacer()

                        Text(formatTime(viewModel.getLiveActivityOffset(for: prayerName)))
                            .font(.custom("Nunito-SemiBold", size: 15))
                            .foregroundColor(Color(hex: "#fab555"))
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                    Slider(
                        value: Binding(
                            get: { Double(viewModel.getLiveActivityOffset(for: prayerName)) },
                            set: { newValue in
                                viewModel.updatePrayerLiveActivityOffset(prayerName, offset: Int(newValue))
                            }
                        ),
                        in: 15...720,
                        step: 15
                    )
                    .tint(Color(hex: "#fab555"))
                    .padding(.horizontal, 20)

                    Text("before prayer time (15 min - 12 hours)")
                        .font(.custom("Nunito-Regular", size: 12))
                        .foregroundColor(.gray)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 12)
                }
                .background(Color(hex: "#f5f5f5"))
            }
        }
    }

    // Format time display (e.g., "30 min", "1h 30m", "2h")
    private func formatTime(_ minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes) min"
        } else if minutes % 60 == 0 {
            return "\(minutes / 60)h"
        } else {
            let hours = minutes / 60
            let mins = minutes % 60
            return "\(hours)h \(mins)m"
        }
    }
}

#Preview {
    if #available(iOS 16.1, *) {
        LiveActivitiesSettingsView(prayerFetcher: PrayerTimesFetcher())
    }
}
