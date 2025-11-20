//
//  LiveActivityPreviewView.swift
//  Noorani
//  Copyright © 2025 AP Bros. All rights reserved.
//
//  Preview all Live Activity layouts without needing a physical device

import SwiftUI

/// Preview view to visualize Live Activity designs in the app
struct LiveActivityPreviewView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPrayer = "Fajr"
    @State private var minutesRemaining = 30

    let prayers = ["Fajr", "Dhuhr", "Asr", "Maghrib", "Isha"]

    var body: some View {
        ZStack {
            // Noorani gradient background
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

            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.white)
                            .font(.system(size: 18, weight: .medium))
                    }

                    Text("Live Activity Preview")
                        .font(.custom("Nunito-Regular", size: 24))
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                        .padding(.leading, 10)

                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)

                ScrollView {
                    VStack(spacing: 24) {
                        // Prayer Selector
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Select Prayer")
                                .font(.custom("Nunito-SemiBold", size: 16))
                                .foregroundColor(.black.opacity(0.8))

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(prayers, id: \.self) { prayer in
                                        Button(action: { selectedPrayer = prayer }) {
                                            HStack(spacing: 6) {
                                                Image(systemName: iconForPrayer(prayer))
                                                    .font(.system(size: 14))
                                                Text(prayer)
                                                    .font(.custom("Nunito-Regular", size: 14))
                                            }
                                            .foregroundColor(selectedPrayer == prayer ? .white : .black)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(
                                                selectedPrayer == prayer ?
                                                    Color(hex: "#fab555") : Color.white
                                            )
                                            .clipShape(Capsule())
                                            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)

                        // Time Selector
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Minutes Until Prayer: \(minutesRemaining)")
                                .font(.custom("Nunito-SemiBold", size: 16))
                                .foregroundColor(.black.opacity(0.8))

                            Slider(value: Binding(
                                get: { Double(minutesRemaining) },
                                set: { minutesRemaining = Int($0) }
                            ), in: 1...60, step: 1)
                            .tint(Color(hex: "#fab555"))
                        }
                        .padding(.horizontal, 20)

                        Divider()
                            .padding(.horizontal, 20)

                        // MARK: - Lock Screen Preview
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Lock Screen / Banner")
                                .font(.custom("Nunito-SemiBold", size: 18))
                                .foregroundColor(.black.opacity(0.8))

                            LockScreenPreview(
                                prayerName: selectedPrayer,
                                prayerIcon: iconForPrayer(selectedPrayer),
                                targetTime: Date().addingTimeInterval(Double(minutesRemaining * 60)),
                                formattedTime: formattedPrayerTime()
                            )
                        }
                        .padding(.horizontal, 20)

                        // MARK: - Dynamic Island Expanded
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Dynamic Island - Expanded")
                                .font(.custom("Nunito-SemiBold", size: 18))
                                .foregroundColor(.black.opacity(0.8))

                            DynamicIslandExpandedPreview(
                                prayerName: selectedPrayer,
                                prayerIcon: iconForPrayer(selectedPrayer),
                                targetTime: Date().addingTimeInterval(Double(minutesRemaining * 60)),
                                formattedTime: formattedPrayerTime()
                            )
                        }
                        .padding(.horizontal, 20)

                        // MARK: - Dynamic Island Compact
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Dynamic Island - Compact")
                                .font(.custom("Nunito-SemiBold", size: 18))
                                .foregroundColor(.black.opacity(0.8))

                            DynamicIslandCompactPreview(
                                prayerName: selectedPrayer,
                                prayerIcon: iconForPrayer(selectedPrayer),
                                targetTime: Date().addingTimeInterval(Double(minutesRemaining * 60))
                            )
                        }
                        .padding(.horizontal, 20)

                        // MARK: - Dynamic Island Minimal
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Dynamic Island - Minimal")
                                .font(.custom("Nunito-SemiBold", size: 18))
                                .foregroundColor(.black.opacity(0.8))

                            DynamicIslandMinimalPreview(
                                prayerIcon: iconForPrayer(selectedPrayer)
                            )
                        }
                        .padding(.horizontal, 20)

                        Spacer(minLength: 40)
                    }
                    .padding(.top, 20)
                }
            }
        }
        .navigationBarHidden(true)
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

    private func formattedPrayerTime() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: Date().addingTimeInterval(Double(minutesRemaining * 60)))
    }
}

// MARK: - Lock Screen Preview (matches actual Live Activity)
struct LockScreenPreview: View {
    let prayerName: String
    let prayerIcon: String
    let targetTime: Date
    let formattedTime: String

    var body: some View {
        HStack(spacing: 12) {
            // Left side - App Logo
            Image("Logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 46, height: 46)
                .clipShape(RoundedRectangle(cornerRadius: 10))

            // Middle - Prayer info with SF Symbol
            HStack(spacing: 6) {
                Image(systemName: prayerIcon)
                    .foregroundColor(Color(hex: "#d4892e"))
                    .font(.system(size: 24, weight: .semibold))

                VStack(alignment: .leading, spacing: 1) {
                    Text(prayerName)
                        .font(.custom("Nunito-SemiBold", size: 17))
                        .foregroundColor(Color(red: 0.15, green: 0.1, blue: 0.05))

                    Text(formattedTime)
                        .font(.custom("Nunito-SemiBold", size: 13))
                        .foregroundColor(Color(red: 0.35, green: 0.3, blue: 0.25))
                        .monospacedDigit()
                }
            }

            Spacer()

            // Right side - Large Countdown Timer
            Text(targetTime, style: .timer)
                .font(.system(size: 38, weight: .heavy, design: .rounded))
                .monospacedDigit()
                .multilineTextAlignment(.trailing)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(minWidth: 90, alignment: .trailing)
                .foregroundColor(Color(hex: "#d4892e"))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(hex: "#feecd3").opacity(0.95))
                .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 5)
        )
    }
}

// MARK: - Dynamic Island Expanded Preview (matches actual Live Activity)
struct DynamicIslandExpandedPreview: View {
    let prayerName: String
    let prayerIcon: String
    let targetTime: Date
    let formattedTime: String

    var body: some View {
        HStack {
            // Left side - Prayer info
            HStack(spacing: 6) {
                Image(systemName: prayerIcon)
                    .foregroundColor(Color(hex: "#fab555"))
                    .font(.system(size: 20, weight: .semibold))

                VStack(alignment: .leading, spacing: 2) {
                    Text(prayerName)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    Text(formattedTime)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                        .monospacedDigit()
                }
            }

            Spacer()

            // Right side - Large Timer
            Text(targetTime, style: .timer)
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundColor(Color(hex: "#fab555"))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 40)
                .fill(Color.black)
        )
    }
}

// MARK: - Dynamic Island Compact Preview (matches actual Live Activity)
struct DynamicIslandCompactPreview: View {
    let prayerName: String
    let prayerIcon: String
    let targetTime: Date

    var body: some View {
        HStack(spacing: 0) {
            // Left side - Prayer icon
            Image(systemName: prayerIcon)
                .foregroundColor(Color(hex: "#fab555"))
                .font(.system(size: 12, weight: .semibold))
                .frame(width: 40)

            Spacer()

            // Right side - Countdown timer
            Text(targetTime, style: .timer)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundColor(Color(hex: "#fab555"))
                .frame(width: 45)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(Color.black)
        )
        .frame(maxWidth: 180)
    }
}

// MARK: - Dynamic Island Minimal Preview (matches actual Live Activity)
struct DynamicIslandMinimalPreview: View {
    let prayerIcon: String

    var body: some View {
        Image(systemName: prayerIcon)
            .foregroundColor(Color(hex: "#fab555"))
            .font(.system(size: 11, weight: .semibold))
            .frame(width: 36, height: 36)
            .background(
                Circle()
                    .fill(Color.black)
            )
    }
}

#Preview {
    LiveActivityPreviewView()
}
