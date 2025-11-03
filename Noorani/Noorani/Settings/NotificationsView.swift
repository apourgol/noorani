//
//  NotificationsView.swift
//  Noorani
//
//  Created by Amin Pourgol on 10/20/25.
//  Copyright © 2025 AP Bros. All rights reserved.
//

import SwiftUI
import UserNotifications

struct NotificationsView: View {
    @AppStorage("notificationsEnabled") private var notificationsEnabled: Bool = false
    @AppStorage("fajrNotification") private var fajrNotification: Bool = true
    @AppStorage("sunriseNotification") private var sunriseNotification: Bool = false
    @AppStorage("dhuhrNotification") private var dhuhrNotification: Bool = true
    @AppStorage("sunsetNotification") private var sunsetNotification: Bool = false
    @AppStorage("maghribNotification") private var maghribNotification: Bool = true
    @AppStorage("midnightNotification") private var midnightNotification: Bool = false
    @AppStorage("notificationOffset") private var notificationOffset: Int = 0 // Minutes before prayer
    
    @Environment(\.dismiss) private var dismiss
    @State private var showingPermissionAlert = false
    
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
                        // Master toggle
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Enable Notifications")
                                    .font(.custom("Nunito-Regular", size: 16))
                                    .foregroundColor(.black)
                                
                                Text("Allow prayer time notifications")
                                    .font(.custom("Nunito-Light", size: 14))
                                    .foregroundColor(.black.opacity(0.6))
                            }
                            
                            Spacer()
                            
                            Toggle("", isOn: $notificationsEnabled)
                                .tint(Color(hex: "#fab555"))
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        
                        if notificationsEnabled {
                            // Notification timing
                            VStack(alignment: .leading, spacing: 0) {
                                Text("Notification Timing")
                                    .font(.custom("Nunito-SemiBold", size: 18))
                                    .foregroundColor(.black.opacity(0.8))
                                    .padding(.horizontal, 20)
                                    .padding(.top, 30)
                                
                                HStack {
                                    Text("Minutes before prayer")
                                        .font(.custom("Nunito-Regular", size: 16))
                                        .foregroundColor(.black)
                                    
                                    Spacer()
                                    
                                    HStack(spacing: 15) {
                                        Button(action: {
                                            if notificationOffset > 0 {
                                                notificationOffset -= 1
                                            }
                                        }) {
                                            Image(systemName: "minus.circle")
                                                .foregroundColor(Color(hex: "#fab555"))
                                                .font(.system(size: 24))
                                        }
                                        
                                        Text("\(notificationOffset)")
                                            .font(.custom("Nunito-SemiBold", size: 16))
                                            .foregroundColor(.black)
                                            .frame(minWidth: 30)
                                        
                                        Button(action: {
                                            if notificationOffset < 60 {
                                                notificationOffset += 1
                                            }
                                        }) {
                                            Image(systemName: "plus.circle")
                                                .foregroundColor(Color(hex: "#fab555"))
                                                .font(.system(size: 24))
                                        }
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.top, 10)
                                
                                // Prayer-specific toggles
                                Text("Prayer Notifications")
                                    .font(.custom("Nunito-SemiBold", size: 18))
                                    .foregroundColor(.black.opacity(0.8))
                                    .padding(.horizontal, 20)
                                    .padding(.top, 30)
                                
                                VStack(spacing: 1) {
                                    NotificationToggleRow(title: "Fajr", isOn: $fajrNotification)
                                    Divider().background(Color.gray.opacity(0.3))
                                    
                                    NotificationToggleRow(title: "Sunrise", isOn: $sunriseNotification)
                                    Divider().background(Color.gray.opacity(0.3))
                                    
                                    NotificationToggleRow(title: "Dhuhr", isOn: $dhuhrNotification)
                                    Divider().background(Color.gray.opacity(0.3))
                                    
                                    NotificationToggleRow(title: "Sunset", isOn: $sunsetNotification)
                                    Divider().background(Color.gray.opacity(0.3))
                                    
                                    NotificationToggleRow(title: "Maghrib", isOn: $maghribNotification)
                                    Divider().background(Color.gray.opacity(0.3))
                                    
                                    NotificationToggleRow(title: "Midnight", isOn: $midnightNotification)
                                }
                                .padding(.horizontal, 20)
                                .padding(.top, 10)
                            }
                        }
                    }
                }
                
                Spacer()
            }
        }
        .navigationBarHidden(true)
        .gesture(
            // Add swipe back gesture
            DragGesture()
                .onEnded { gesture in
                    if gesture.translation.width > 100 && abs(gesture.translation.height) < 50 {
                        dismiss()
                    }
                }
        )
        .onChange(of: notificationsEnabled) { _, enabled in
            if enabled {
                requestNotificationPermission()
            }
        }
        .alert("Notification Permission", isPresented: $showingPermissionAlert) {
            Button("Settings") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            Button("Cancel", role: .cancel) {
                notificationsEnabled = false
            }
        } message: {
            Text("Please enable notifications in Settings to receive prayer time alerts.")
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async {
                if !granted {
                    showingPermissionAlert = true
                }
            }
        }
    }
}

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

#Preview {
    NotificationsView()
}
