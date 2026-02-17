//
//  PrayerCountdownLiveActivity.swift
//  NooraniWidget
//  Copyright © 2025 AP Bros. All rights reserved.
//

import ActivityKit
import WidgetKit
import SwiftUI

@available(iOS 16.1, *)
struct PrayerCountdownLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PrayerCountdownAttributes.self) { context in
            // Lock screen/banner UI
            LockScreenLiveActivityView(context: context)
                .activitySystemActionForegroundColor(Color(hex: "#d4892e"))

        } dynamicIsland: { context in
            DynamicIsland {
                // EXPANDED VIEW - Prayer info on left with time below, timer on right
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Image(systemName: PrayerCountdownAttributes.icon(for: context.state.prayerName))
                                .font(.system(size: 22, weight: .medium))
                                .foregroundStyle(Color(hex: "#fab555"))
                            Text(context.state.prayerName)
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                        Text(context.state.formattedTime)
                            .font(.system(size: 15))
                            .foregroundStyle(.gray)
                            .padding(.leading, 30)
                    }
                }

                DynamicIslandExpandedRegion(.trailing) {
                    TimerText(targetTime: context.state.targetTime)
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(hex: "#fab555"))
                }

            } compactLeading: {
                // Icon on left - small
                Image(systemName: PrayerCountdownAttributes.icon(for: context.state.prayerName))
                    .font(.caption2)
                    .foregroundStyle(Color(hex: "#fab555"))

            } compactTrailing: {
                // Timer on right - compact format (shorter)
                TimerText(targetTime: context.state.targetTime, compact: true)
                    .font(.caption2)
                    .foregroundStyle(Color(hex: "#fab555"))

            } minimal: {
                Image(systemName: PrayerCountdownAttributes.icon(for: context.state.prayerName))
                    .foregroundStyle(Color(hex: "#fab555"))
            }
        }
    }
}

// MARK: - Timer Text (shows countdown or 00:00 when done)
@available(iOS 16.1, *)
struct TimerText: View {
    let targetTime: Date
    var compact: Bool = false

    var body: some View {
        if targetTime.timeIntervalSinceNow > 0 {
            if compact {
                // Shorter format for compact Dynamic Island
                Text(shortTimeString)
                    .monospacedDigit()
            } else {
                Text(targetTime, style: .timer)
                    .monospacedDigit()
                    .contentTransition(.identity)
            }
        } else {
            Text("0:00")
                .monospacedDigit()
        }
    }

    private var shortTimeString: String {
        let remaining = Int(targetTime.timeIntervalSinceNow)
        let minutes = remaining / 60
        let seconds = remaining % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Lock Screen View (Compact Design)
@available(iOS 16.1, *)
struct LockScreenLiveActivityView: View {
    let context: ActivityViewContext<PrayerCountdownAttributes>

    var body: some View {
        LockScreenContent(
            prayerName: context.state.prayerName,
            formattedTime: context.state.formattedTime,
            targetTime: context.state.targetTime
        )
    }
}

// MARK: - Reusable Lock Screen Content (for previews)
@available(iOS 16.1, *)
struct LockScreenContent: View {
    let prayerName: String
    let formattedTime: String
    let targetTime: Date

    var body: some View {
        HStack(spacing: 12) {
            // Left side - Prayer icon
            Image(systemName: PrayerCountdownAttributes.icon(for: prayerName))
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(Color(hex: "#fab555"))
                .frame(width: 36, height: 36)

            // Middle - Prayer name and time
            VStack(alignment: .leading, spacing: 2) {
                Text(prayerName)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(formattedTime)
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            // Right side - Timer RIGHT-ALIGNED
            TimerText(targetTime: targetTime)
                .font(.system(size: 24, weight: .semibold, design: .rounded))
                .foregroundStyle(Color(hex: "#d4892e"))
                .multilineTextAlignment(.trailing)
                .frame(alignment: .trailing)
                .privacySensitive()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

// MARK: - Dynamic Island Expanded Content (for previews)
@available(iOS 16.1, *)
struct DynamicIslandExpandedContent: View {
    let prayerName: String
    let formattedTime: String
    let targetTime: Date

    var body: some View {
        HStack {
            // Left - Prayer info
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Image(systemName: PrayerCountdownAttributes.icon(for: prayerName))
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(Color(hex: "#fab555"))
                    Text(prayerName)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.white)
                }
                Text(formattedTime)
                    .font(.system(size: 15))
                    .foregroundStyle(.gray)
            }

            Spacer()

            // Right - Big timer
            TimerText(targetTime: targetTime)
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(Color(hex: "#fab555"))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(Color.black)
        .clipShape(RoundedRectangle(cornerRadius: 44))
    }
}

// MARK: - Dynamic Island Compact Content (for previews)
@available(iOS 16.1, *)
struct DynamicIslandCompactContent: View {
    let prayerName: String
    let targetTime: Date

    var body: some View {
        HStack {
            // Left - Icon
            Image(systemName: PrayerCountdownAttributes.icon(for: prayerName))
                .foregroundStyle(Color(hex: "#fab555"))

            Spacer()

            // Right - Timer
            TimerText(targetTime: targetTime)
                .foregroundStyle(Color(hex: "#fab555"))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.black)
        .clipShape(Capsule())
    }
}

// MARK: - Dynamic Island Minimal Content (for previews)
@available(iOS 16.1, *)
struct DynamicIslandMinimalContent: View {
    let prayerName: String

    var body: some View {
        Image(systemName: PrayerCountdownAttributes.icon(for: prayerName))
            .foregroundStyle(Color(hex: "#fab555"))
            .padding(8)
            .background(Color.black)
            .clipShape(Circle())
    }
}

// MARK: - Previews
@available(iOS 16.1, *)
struct LockScreenPreview_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Lock Screen Preview
            VStack(alignment: .leading, spacing: 8) {
                Text("Lock Screen")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                LockScreenContent(
                    prayerName: "Maghrib",
                    formattedTime: "6:07 PM",
                    targetTime: Date().addingTimeInterval(3600 + 1800) // 1h 30m
                )
                .background(Color(hex: "#feecd3"))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }

            // Dynamic Island Expanded
            VStack(alignment: .leading, spacing: 8) {
                Text("Dynamic Island - Expanded")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                DynamicIslandExpandedContent(
                    prayerName: "Maghrib",
                    formattedTime: "6:07 PM",
                    targetTime: Date().addingTimeInterval(3600 + 1800)
                )
            }

            // Dynamic Island Compact
            VStack(alignment: .leading, spacing: 8) {
                Text("Dynamic Island - Compact")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                DynamicIslandCompactContent(
                    prayerName: "Maghrib",
                    targetTime: Date().addingTimeInterval(3600 + 1800)
                )
            }

            // Dynamic Island Minimal
            VStack(alignment: .leading, spacing: 8) {
                Text("Dynamic Island - Minimal")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                DynamicIslandMinimalContent(prayerName: "Maghrib")
            }
        }
        .padding()
        .previewDisplayName("All Live Activity Views")
    }
}

// Preview helper extension
@available(iOS 16.1, *)
extension PrayerCountdownAttributes {
    static var preview: PrayerCountdownAttributes {
        PrayerCountdownAttributes(prayerId: "maghrib_2025-02-16")
    }
}

