//
//  PrayerTimeCalculationView.swift
//  Noorani
//
//  Created by Amin Pourgol on 10/20/25.
//  Copyright © 2025 AP Bros. All rights reserved.
//

import SwiftUI

// MARK: - Views

struct PrayerTimeCalculationView: View {
    @ObservedObject var prayerFetcher: PrayerTimesFetcher
    @AppStorage("timeFormat") private var timeFormat: String = "12" // "12" or "24"
    @Environment(\.dismiss) private var dismiss

    var body: some View {
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
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.white)
                            .font(.system(size: 18, weight: .medium))
                    }

                    Text("Prayer Time Calculation")
                        .font(.custom("Nunito-Regular", size: 24))
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                        .padding(.leading, 10)

                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)

                // Method selection list
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Calculation Methods Section
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Calculation Methods")
                                .font(.custom("Nunito-Regular", size: 18))
                                .fontWeight(.semibold)
                                .foregroundColor(.black.opacity(0.8))
                                .padding(.horizontal, 20)

                            VStack(spacing: 1) {
                                ForEach(prayerFetcher.availableMethods) { method in
                                    EnhancedCalculationMethodRow(
                                        method: method,
                                        isSelected: prayerFetcher.selectedMethod?.id == method.id
                                    ) {
                                        prayerFetcher.selectMethod(method)
                                    }

                                    if method.id != prayerFetcher.availableMethods.last?.id {
                                        Divider()
                                            .background(Color.gray.opacity(0.15))
                                            .padding(.leading, 20)
                                    }
                                }
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white)
                                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
                            )
                            .padding(.horizontal, 20)
                        }

                        // Time Format Section
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Time Format")
                                .font(.custom("Nunito-Regular", size: 18))
                                .fontWeight(.semibold)
                                .foregroundColor(.black.opacity(0.8))
                                .padding(.horizontal, 20)

                            VStack(spacing: 1) {
                                TimeFormatRow(
                                    title: "12 Hour (AM/PM)",
                                    format: "12",
                                    currentFormat: timeFormat
                                ) {
                                    timeFormat = "12"
                                }

                                Divider()
                                    .background(Color.gray.opacity(0.15))
                                    .padding(.leading, 20)

                                TimeFormatRow(
                                    title: "24 Hour",
                                    format: "24",
                                    currentFormat: timeFormat
                                ) {
                                    timeFormat = "24"
                                }
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white)
                                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
                            )
                            .padding(.horizontal, 20)
                        }

                        // Prayer Visibility Section
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Optional Prayer Times")
                                .font(.custom("Nunito-Regular", size: 18))
                                .fontWeight(.semibold)
                                .foregroundColor(.black.opacity(0.8))
                                .padding(.horizontal, 20)

                            VStack(spacing: 1) {
                                PrayerToggleRow(title: "Asr", isOn: $prayerFetcher.showAsr)
                                Divider().background(Color.gray.opacity(0.15)).padding(.leading, 20)
                                
                                PrayerToggleRow(title: "Isha", isOn: $prayerFetcher.showIsha)
                                Divider().background(Color.gray.opacity(0.15)).padding(.leading, 20)
                                
                                PrayerToggleRow(title: "Midnight", isOn: $prayerFetcher.showMidnight)
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white)
                                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
                            )
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.top, 20)
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
    }
}

struct EnhancedCalculationMethodRow: View {
    let method: CalculationMethod
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(method.name)
                        .font(.custom("Nunito-Regular", size: 16))
                        .fontWeight(.medium)
                        .foregroundColor(.black)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color(hex: "#fab555"))
                        .font(.system(size: 20, weight: .medium))
                } else {
                    Image(systemName: "circle")
                        .foregroundColor(.gray.opacity(0.4))
                        .font(.system(size: 20, weight: .light))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CalculationMethodRow: View {
    let methodID: Int
    let methodName: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(methodName)
                        .font(.custom("Nunito-Regular", size: 16))
                        .foregroundColor(.black)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(Color(hex: "#fab555"))
                        .font(.system(size: 16, weight: .medium))
                }
            }
            .padding(.vertical, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct TimeFormatRow: View {
    let title: String
    let format: String
    let currentFormat: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                Text(title)
                    .font(.custom("Nunito-Regular", size: 16))
                    .foregroundColor(.black)

                Spacer()

                if currentFormat == format {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color(hex: "#fab555"))
                        .font(.system(size: 20, weight: .medium))
                } else {
                    Image(systemName: "circle")
                        .foregroundColor(.gray.opacity(0.4))
                        .font(.system(size: 20, weight: .light))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct PrayerToggleRow: View {
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
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
}

#Preview {
    PrayerTimeCalculationView(prayerFetcher: PrayerTimesFetcher())
}

