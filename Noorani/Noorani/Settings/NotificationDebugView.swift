//
//  NotificationDebugView.swift
//  Noorani
//  Copyright © 2025 AP Bros. All rights reserved.
//

import SwiftUI
import UserNotifications

struct NotificationDebugView: View {
    @State private var pendingNotifications: [UNNotificationRequest] = []
    @State private var isLoading = true
    @State private var lastScheduledDate: Date?
    @State private var fajrCount = 0
    @State private var dateRange = ""
    @State private var daysCoverage = 0
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [
                        Color.nooraniPrimary,
                        Color.nooraniSecondary,
                        Color.white
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        if isLoading {
                            ProgressView("Loading notification data...")
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding()
                        } else {
                            // Summary Card
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Notification Summary")
                                    .font(.custom("Nunito-Regular", size: 20))
                                    .fontWeight(.bold)

                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Total Scheduled")
                                            .font(.custom("Nunito-Regular", size: 14))
                                            .foregroundColor(.gray)
                                        Text("\(pendingNotifications.count)")
                                            .font(.custom("Nunito-Regular", size: 28))
                                            .fontWeight(.bold)
                                            .foregroundColor(pendingNotifications.count > 20 ? .green : .orange)
                                    }

                                    Spacer()

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Fajr Notifications")
                                            .font(.custom("Nunito-Regular", size: 14))
                                            .foregroundColor(.gray)
                                        Text("\(fajrCount)")
                                            .font(.custom("Nunito-Regular", size: 28))
                                            .fontWeight(.bold)
                                            .foregroundColor(fajrCount > 25 ? .green : .orange)
                                    }
                                }

                                Divider()

                                if pendingNotifications.isEmpty {
                                    HStack {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundColor(.red)
                                        Text("No notifications scheduled!")
                                            .font(.custom("Nunito-Regular", size: 14))
                                            .foregroundColor(.red)
                                    }
                                } else {
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack {
                                            Image(systemName: daysCoverage >= 25 ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                                                .foregroundColor(daysCoverage >= 25 ? .green : .orange)
                                            Text("Coverage: \(daysCoverage) days")
                                                .font(.custom("Nunito-Regular", size: 14))
                                        }

                                        if !dateRange.isEmpty {
                                            Text(dateRange)
                                                .font(.custom("Nunito-Regular", size: 12))
                                                .foregroundColor(.gray)
                                        }

                                        if daysCoverage < 25 {
                                            Text("⚠️ Less than 30 days scheduled. You'll need to open the app again soon.")
                                                .font(.custom("Nunito-Regular", size: 12))
                                                .foregroundColor(.orange)
                                                .padding(.top, 4)
                                        } else {
                                            Text("✅ Full month scheduled! You can close the app for \(daysCoverage) days.")
                                                .font(.custom("Nunito-Regular", size: 12))
                                                .foregroundColor(.green)
                                                .padding(.top, 4)
                                        }
                                    }
                                }

                                if let lastDate = lastScheduledDate {
                                    Divider()
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Last 30-Day Schedule")
                                            .font(.custom("Nunito-Regular", size: 14))
                                            .foregroundColor(.gray)
                                        Text(lastDate, style: .relative)
                                            .font(.custom("Nunito-Regular", size: 14))
                                    }
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white)
                                    .shadow(color: Color.black.opacity(0.05), radius: 8)
                            )
                            .padding(.horizontal)

                            // Scheduling Metadata Card
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Smart Scheduling Status")
                                    .font(.custom("Nunito-Regular", size: 18))
                                    .fontWeight(.bold)

                                let lastScheduledLat = UserDefaults.standard.double(forKey: "lastScheduledNotificationLat")
                                let lastScheduledLng = UserDefaults.standard.double(forKey: "lastScheduledNotificationLng")
                                let lastScheduledMethodID = UserDefaults.standard.integer(forKey: "lastScheduledNotificationMethodID")

                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Image(systemName: "mappin.circle.fill")
                                            .foregroundColor(.blue)
                                        Text("Scheduled Location:")
                                            .font(.custom("Nunito-Regular", size: 14))
                                            .fontWeight(.medium)
                                    }
                                    Text("(\(String(format: "%.4f", lastScheduledLat)), \(String(format: "%.4f", lastScheduledLng)))")
                                        .font(.custom("Nunito-Regular", size: 12))
                                        .foregroundColor(.gray)
                                        .padding(.leading, 24)

                                    Divider()

                                    HStack {
                                        Image(systemName: "clock.fill")
                                            .foregroundColor(.green)
                                        Text("Next Reschedule:")
                                            .font(.custom("Nunito-Regular", size: 14))
                                            .fontWeight(.medium)
                                    }
                                    if let lastDate = lastScheduledDate {
                                        let daysRemaining = Calendar.current.dateComponents([.day], from: Date(), to: lastDate).day ?? 0
                                        if daysRemaining < 7 {
                                            Text("⚠️ Soon! (\(daysRemaining) days until reschedule)")
                                                .font(.custom("Nunito-Regular", size: 12))
                                                .foregroundColor(.orange)
                                                .padding(.leading, 24)
                                        } else {
                                            Text("In \(daysRemaining - 7) days (when < 7 days remain)")
                                                .font(.custom("Nunito-Regular", size: 12))
                                                .foregroundColor(.gray)
                                                .padding(.leading, 24)
                                        }
                                    } else {
                                        Text("Never scheduled")
                                            .font(.custom("Nunito-Regular", size: 12))
                                            .foregroundColor(.red)
                                            .padding(.leading, 24)
                                    }

                                    Divider()

                                    HStack {
                                        Image(systemName: "function")
                                            .foregroundColor(.purple)
                                        Text("Calculation Method:")
                                            .font(.custom("Nunito-Regular", size: 14))
                                            .fontWeight(.medium)
                                    }
                                    Text("Method ID: \(lastScheduledMethodID)")
                                        .font(.custom("Nunito-Regular", size: 12))
                                        .foregroundColor(.gray)
                                        .padding(.leading, 24)

                                    Divider()

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Rescheduling triggers:")
                                            .font(.custom("Nunito-Regular", size: 12))
                                            .fontWeight(.medium)
                                            .foregroundColor(.gray)
                                        Text("• Location changes > 5km")
                                            .font(.custom("Nunito-Regular", size: 11))
                                            .foregroundColor(.gray)
                                        Text("• < 7 days of notifications remaining")
                                            .font(.custom("Nunito-Regular", size: 11))
                                            .foregroundColor(.gray)
                                        Text("• Calculation method changes")
                                            .font(.custom("Nunito-Regular", size: 11))
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white)
                                    .shadow(color: Color.black.opacity(0.05), radius: 8)
                            )
                            .padding(.horizontal)

                            // Fajr Schedule
                            if fajrCount > 0 {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Upcoming Fajr Notifications")
                                        .font(.custom("Nunito-Regular", size: 18))
                                        .fontWeight(.bold)

                                    ForEach(pendingNotifications.prefix(10), id: \.identifier) { notification in
                                        if notification.identifier.contains("fajr") {
                                            if let trigger = notification.trigger as? UNCalendarNotificationTrigger,
                                               let triggerDate = trigger.nextTriggerDate() {
                                                HStack {
                                                    VStack(alignment: .leading, spacing: 2) {
                                                        Text(triggerDate, style: .date)
                                                            .font(.custom("Nunito-Regular", size: 14))
                                                        Text(triggerDate, style: .time)
                                                            .font(.custom("Nunito-Regular", size: 12))
                                                            .foregroundColor(.gray)
                                                    }
                                                    Spacer()
                                                    Text(triggerDate, style: .relative)
                                                        .font(.custom("Nunito-Regular", size: 12))
                                                        .foregroundColor(.gray)
                                                }
                                                .padding(.vertical, 8)
                                                Divider()
                                            }
                                        }
                                    }
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.white)
                                        .shadow(color: Color.black.opacity(0.05), radius: 8)
                                )
                                .padding(.horizontal)
                            }

                            // All Notifications List
                            VStack(alignment: .leading, spacing: 12) {
                                Text("All Scheduled Notifications")
                                    .font(.custom("Nunito-Regular", size: 18))
                                    .fontWeight(.bold)

                                if pendingNotifications.isEmpty {
                                    Text("No notifications scheduled")
                                        .font(.custom("Nunito-Regular", size: 14))
                                        .foregroundColor(.gray)
                                } else {
                                    ForEach(pendingNotifications.prefix(50), id: \.identifier) { notification in
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(notification.content.title)
                                                .font(.custom("Nunito-Regular", size: 14))
                                                .fontWeight(.medium)

                                            if let trigger = notification.trigger as? UNCalendarNotificationTrigger,
                                               let triggerDate = trigger.nextTriggerDate() {
                                                Text("\(triggerDate.formatted(date: .abbreviated, time: .shortened))")
                                                    .font(.custom("Nunito-Regular", size: 12))
                                                    .foregroundColor(.gray)
                                            }

                                            Text(notification.identifier)
                                                .font(.custom("Nunito-Regular", size: 10))
                                                .foregroundColor(.gray.opacity(0.7))
                                        }
                                        .padding(.vertical, 8)
                                        Divider()
                                    }

                                    if pendingNotifications.count > 50 {
                                        Text("... and \(pendingNotifications.count - 50) more")
                                            .font(.custom("Nunito-Regular", size: 12))
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white)
                                    .shadow(color: Color.black.opacity(0.05), radius: 8)
                            )
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Debug Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        loadNotifications()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
        .onAppear {
            loadNotifications()
        }
    }

    private func loadNotifications() {
        isLoading = true

        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            DispatchQueue.main.async {
                self.pendingNotifications = requests.sorted { req1, req2 in
                    guard let t1 = (req1.trigger as? UNCalendarNotificationTrigger)?.nextTriggerDate(),
                          let t2 = (req2.trigger as? UNCalendarNotificationTrigger)?.nextTriggerDate() else {
                        return false
                    }
                    return t1 < t2
                }

                // Count Fajr start notifications (excluding expiration)
                self.fajrCount = requests.filter { $0.identifier.contains("fajr") && !$0.identifier.contains("expiration") }.count

                // Count expiration notifications for debugging
                let fajrExpirationCount = requests.filter { $0.identifier.contains("fajr") && $0.identifier.contains("expiration") }.count
                let dhuhrExpirationCount = requests.filter { $0.identifier.contains("dhuhr") && $0.identifier.contains("expiration") }.count
                let maghribExpirationCount = requests.filter { $0.identifier.contains("maghrib") && $0.identifier.contains("expiration") }.count

                print("🔍 DEBUG: Fajr start: \(self.fajrCount), Fajr expiration: \(fajrExpirationCount)")
                print("🔍 DEBUG: Dhuhr expiration: \(dhuhrExpirationCount), Maghrib expiration: \(maghribExpirationCount)")

                // Calculate ACTUAL daily coverage based on Fajr notifications (most reliable indicator)
                var fajrDates: [Date] = []
                for request in requests {
                    if request.identifier.contains("fajr") && !request.identifier.contains("expiration"),
                       let trigger = request.trigger as? UNCalendarNotificationTrigger,
                       let triggerDate = trigger.nextTriggerDate() {
                        // Normalize to day only (ignore time)
                        let dayOnly = Calendar.current.startOfDay(for: triggerDate)
                        fajrDates.append(dayOnly)
                    }
                }

                // Count unique days with Fajr notifications
                let uniqueFajrDays = Set(fajrDates)
                self.daysCoverage = uniqueFajrDays.count

                if let earliest = fajrDates.min(), let latest = fajrDates.max() {
                    let formatter = DateFormatter()
                    formatter.dateStyle = .short
                    self.dateRange = "\(formatter.string(from: earliest)) - \(formatter.string(from: latest))"
                } else {
                    self.dateRange = "No coverage"
                }

                // Load last scheduled date
                let lastScheduled = UserDefaults.standard.double(forKey: "lastScheduledNotificationDate")
                if lastScheduled > 0 {
                    self.lastScheduledDate = Date(timeIntervalSince1970: lastScheduled)
                }

                self.isLoading = false
            }
        }
    }
}

#Preview {
    NotificationDebugView()
}
