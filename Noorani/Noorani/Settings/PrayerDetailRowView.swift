//
//  PrayerDetailRowView.swift
//  Noorani
//  Copyright © 2025 AP Bros. All rights reserved.
//

import SwiftUI

struct PrayerDetailRowView: View {
    let prayerName: String
    @ObservedObject var viewModel: NotificationsViewModel
    @Binding var isExpanded: Bool

    // Get the appropriate published properties based on prayer name
    private var startNotificationEnabled: Bool {
        switch prayerName.lowercased() {
        case "fajr": return viewModel.fajrStartNotificationEnabled
        case "dhuhr": return viewModel.dhuhrStartNotificationEnabled
        case "asr": return viewModel.asrStartNotificationEnabled
        case "maghrib": return viewModel.maghribStartNotificationEnabled
        case "isha": return viewModel.ishaStartNotificationEnabled
        default: return false
        }
    }

    private var startNotificationOffset: Int {
        switch prayerName.lowercased() {
        case "fajr": return viewModel.fajrStartNotificationOffset
        case "dhuhr": return viewModel.dhuhrStartNotificationOffset
        case "asr": return viewModel.asrStartNotificationOffset
        case "maghrib": return viewModel.maghribStartNotificationOffset
        case "isha": return viewModel.ishaStartNotificationOffset
        default: return 0
        }
    }

    private var expireNotificationEnabled: Bool {
        switch prayerName.lowercased() {
        case "fajr": return viewModel.fajrExpireNotificationEnabled
        case "dhuhr": return viewModel.dhuhrExpireNotificationEnabled
        case "asr": return viewModel.asrExpireNotificationEnabled
        case "maghrib": return viewModel.maghribExpireNotificationEnabled
        case "isha": return viewModel.ishaExpireNotificationEnabled
        default: return false
        }
    }

    private var expireNotificationOffset: Int {
        switch prayerName.lowercased() {
        case "fajr": return viewModel.fajrExpireNotificationOffset
        case "dhuhr": return viewModel.dhuhrExpireNotificationOffset
        case "asr": return viewModel.asrExpireNotificationOffset
        case "maghrib": return viewModel.maghribExpireNotificationOffset
        case "isha": return viewModel.ishaExpireNotificationOffset
        default: return 15
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header row (always visible)
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Text(prayerName)
                        .font(.custom("Nunito-Regular", size: 16))
                        .foregroundColor(.black)

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(Color(hex: "#d89a3d"))
                        .font(.system(size: 16, weight: .semibold))
                }
                .padding(.vertical, 16)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())

            // Expanded detail section
            if isExpanded {
                VStack(alignment: .leading, spacing: 20) {
                    // Start notification section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Prayer Start Notification")
                                    .font(.custom("Nunito-SemiBold", size: 15))
                                    .foregroundColor(.black.opacity(0.9))

                                Text("Alert when \(prayerName) time begins")
                                    .font(.custom("Nunito-Light", size: 12))
                                    .foregroundColor(.black.opacity(0.6))
                            }

                            Spacer()

                            Toggle("", isOn: Binding(
                                get: { startNotificationEnabled },
                                set: { viewModel.updatePrayerStartNotificationEnabled(prayer: prayerName, enabled: $0) }
                            ))
                            .tint(Color(hex: "#fab555"))
                        }

                        if startNotificationEnabled {
                            // Offset controls
                            VStack(alignment: .leading, spacing: 12) {
                                // Custom +/- controls
                                HStack(spacing: 12) {
                                    Text("Minutes before:")
                                        .font(.custom("Nunito-Regular", size: 14))
                                        .foregroundColor(.black.opacity(0.8))

                                    Spacer()

                                    // Decrement button
                                    Button(action: {
                                        let newValue = max(0, startNotificationOffset - 5)
                                        viewModel.updatePrayerStartNotificationOffset(prayer: prayerName, offset: newValue)
                                    }) {
                                        Image(systemName: "minus.circle.fill")
                                            .font(.system(size: 28))
                                            .foregroundColor(startNotificationOffset <= 0 ? Color.gray.opacity(0.3) : Color(hex: "#fab555"))
                                    }
                                    .disabled(startNotificationOffset <= 0)

                                    // Display value
                                    Text("\(startNotificationOffset)")
                                        .font(.custom("Nunito-Bold", size: 20))
                                        .foregroundColor(.black)
                                        .frame(minWidth: 40)

                                    // Increment button (UPDATED MAX TO 60)
                                    Button(action: {
                                        let newValue = min(60, startNotificationOffset + 5)
                                        viewModel.updatePrayerStartNotificationOffset(prayer: prayerName, offset: newValue)
                                    }) {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 28))
                                            // Updated condition for color
                                            .foregroundColor(startNotificationOffset >= 60 ? Color.gray.opacity(0.3) : Color(hex: "#fab555"))
                                    }
                                    // Updated disabled condition
                                    .disabled(startNotificationOffset >= 60)
                                }

                                // Preset buttons (scrollable)
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach([0, 5, 10, 15, 30, 45, 60], id: \.self) { minutes in
                                            Button(action: {
                                                viewModel.updatePrayerStartNotificationOffset(prayer: prayerName, offset: minutes)
                                            }) {
                                                Text("\(minutes)m")
                                                    .font(.custom("Nunito-Regular", size: 13))
                                                    .foregroundColor(startNotificationOffset == minutes ? .white : .black)
                                                    .padding(.horizontal, 12)
                                                    .padding(.vertical, 6)
                                                    .background(
                                                        startNotificationOffset == minutes ?
                                                            Color(hex: "#fab555") : Color.gray.opacity(0.2)
                                                    )
                                                    .clipShape(Capsule())
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.leading, 8)
                        }
                    }

                    // Divider
                    Divider()
                        .background(Color.gray.opacity(0.2))

                    // Expiration notification section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Prayer Expiration Alert")
                                    .font(.custom("Nunito-SemiBold", size: 15))
                                    .foregroundColor(.black.opacity(0.9))

                                Text("Reminder before \(prayerName) time ends")
                                    .font(.custom("Nunito-Light", size: 12))
                                    .foregroundColor(.black.opacity(0.6))
                            }

                            Spacer()

                            Toggle("", isOn: Binding(
                                get: { expireNotificationEnabled },
                                set: { viewModel.updatePrayerExpireNotificationEnabled(prayer: prayerName, enabled: $0) }
                            ))
                            .tint(Color(hex: "#fab555"))
                        }

                        if expireNotificationEnabled {
                            // Offset controls
                            VStack(alignment: .leading, spacing: 12) {
                                // Custom +/- controls
                                HStack(spacing: 12) {
                                    Text("Minutes before expiration:")
                                        .font(.custom("Nunito-Regular", size: 14))
                                        .foregroundColor(.black.opacity(0.8))

                                    Spacer()

                                    // Decrement button
                                    Button(action: {
                                        let newValue = max(5, expireNotificationOffset - 5)
                                        viewModel.updatePrayerExpireNotificationOffset(prayer: prayerName, offset: newValue)
                                    }) {
                                        Image(systemName: "minus.circle.fill")
                                            .font(.system(size: 28))
                                            .foregroundColor(expireNotificationOffset <= 5 ? Color.gray.opacity(0.3) : Color(hex: "#fab555"))
                                    }
                                    .disabled(expireNotificationOffset <= 5)

                                    // Display value
                                    Text("\(expireNotificationOffset)")
                                        .font(.custom("Nunito-Bold", size: 20))
                                        .foregroundColor(.black)
                                        .frame(minWidth: 40)

                                    // Increment button (UPDATED MAX TO 60)
                                    Button(action: {
                                        let newValue = min(60, expireNotificationOffset + 5)
                                        viewModel.updatePrayerExpireNotificationOffset(prayer: prayerName, offset: newValue)
                                    }) {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 28))
                                            // Updated condition for color
                                            .foregroundColor(expireNotificationOffset >= 60 ? Color.gray.opacity(0.3) : Color(hex: "#fab555"))
                                    }
                                    // Updated disabled condition
                                    .disabled(expireNotificationOffset >= 60)
                                }

                                // Preset buttons (scrollable)
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        // REMOVED 90, 120, 180 to stay consistent with 60 max
                                        ForEach([5, 10, 15, 30, 45, 60], id: \.self) { minutes in
                                            Button(action: {
                                                viewModel.updatePrayerExpireNotificationOffset(prayer: prayerName, offset: minutes)
                                            }) {
                                                Text("\(minutes)m")
                                                    .font(.custom("Nunito-Regular", size: 13))
                                                    .foregroundColor(expireNotificationOffset == minutes ? .white : .black)
                                                    .padding(.horizontal, 12)
                                                    .padding(.vertical, 6)
                                                    .background(
                                                        expireNotificationOffset == minutes ?
                                                            Color(hex: "#fab555") : Color.gray.opacity(0.2)
                                                    )
                                                    .clipShape(Capsule())
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.leading, 8)
                        }
                    }
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 4)
                .background(Color.gray.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }
}
