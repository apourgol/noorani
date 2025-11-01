//
//  PrayerTimeCalculationView.swift
//  Noorani
//
//  Created by Amin Pourgol on 10/20/25.
//  Copyright © 2025 AP Bros. All rights reserved.
//

import SwiftUI

struct PrayerTimeCalculationView: View {
    @ObservedObject var prayerFetcher: PrayerTimesFetcher
    @AppStorage("timeFormat") private var timeFormat: String = "12" // "12" or "24"
    @Environment(\.dismiss) private var dismiss
    
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
                        // Current Selection Summary
                        if let selectedMethod = prayerFetcher.selectedMethod {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Current Method")
                                    .font(.custom("Nunito-Regular", size: 18))
                                    .fontWeight(.semibold)
                                    .foregroundColor(.black.opacity(0.8))
                                    .padding(.horizontal, 20)
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(selectedMethod.name)
                                                .font(.custom("Nunito-Regular", size: 16))
                                                .fontWeight(.semibold)
                                                .foregroundColor(.black)
                                            
                                            if let params = selectedMethod.params {
                                                VStack(alignment: .leading, spacing: 2) {
                                                    if let fajr = params.Fajr {
                                                        Text("Fajr: \(fajr, specifier: "%.1f")°")
                                                            .font(.caption)
                                                            .foregroundColor(.secondary)
                                                    }
                                                    
                                                    if let isha = params.Isha {
                                                        Text("Isha: \(isha.displayValue)")
                                                            .font(.caption)
                                                            .foregroundColor(.secondary)
                                                    }
                                                    
                                                    if let maghrib = params.Maghrib {
                                                        Text("Maghrib: \(maghribDisplayValue(maghrib))")
                                                            .font(.caption)
                                                            .foregroundColor(.secondary)
                                                    }
                                                    
                                                    if let midnight = params.Midnight {
                                                        Text("Midnight: \(midnight)")
                                                            .font(.caption)
                                                            .foregroundColor(.secondary)
                                                    }
                                                }
                                            }
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(Color(hex: "#fab555"))
                                            .font(.title2)
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.white.opacity(0.8))
                                            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                                    )
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                        
                        // All Available Methods Section
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("All Calculation Methods")
                                    .font(.custom("Nunito-Regular", size: 18))
                                    .fontWeight(.semibold)
                                    .foregroundColor(.black.opacity(0.8))
                                
                                Spacer()
                                
                                Text("\(prayerFetcher.availableMethods.count) available")
                                    .font(.custom("Nunito-Regular", size: 14))
                                    .foregroundColor(.secondary)
                            }
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
    
    private func maghribDisplayValue(_ maghrib: MethodParams.MaghribParam) -> String {
        switch maghrib {
        case .degrees(let degrees):
            return "\(degrees)°"
        case .minutes(let minutes):
            return minutes
        }
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
                    
                    if let params = method.params {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 12) {
                                if let fajr = params.Fajr {
                                    Text("Fajr: \(fajr, specifier: "%.1f")°")
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                }
                                
                                if let isha = params.Isha {
                                    Text("Isha: \(isha.displayValue)")
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            if let maghrib = params.Maghrib {
                                Text("Maghrib: \(maghribDisplayValue(maghrib))")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                            
                            if let midnight = params.Midnight {
                                Text("Midnight: \(midnight)")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    if let location = method.location {
                        Text("Reference: \(location.latitude, specifier: "%.2f"), \(location.longitude, specifier: "%.2f")")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
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
    
    private func maghribDisplayValue(_ maghrib: MethodParams.MaghribParam) -> String {
        switch maghrib {
        case .degrees(let degrees):
            return "\(degrees)°"
        case .minutes(let minutes):
            return minutes
        }
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

#Preview {
    PrayerTimeCalculationView(prayerFetcher: PrayerTimesFetcher())
}
