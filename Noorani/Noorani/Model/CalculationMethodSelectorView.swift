//
//  CalculationMethodSelectorView.swift
//  Noorani
 //  Copyright © 2025 AP Bros. All rights reserved.
//

import SwiftUI

struct CalculationMethodSelectorView: View {
    @ObservedObject var prayerFetcher: PrayerTimesFetcher
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Calculation Methods")) {
                    ForEach(prayerFetcher.availableMethods) { method in
                        MethodRow(
                            method: method,
                            isSelected: prayerFetcher.selectedMethod?.id == method.id
                        ) {
                            prayerFetcher.selectMethod(method)
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle("Prayer Calculation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct MethodRow: View {
    let method: PrayerCalculationMethod
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(method.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if let params = method.params {
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
                
                if let location = method.location {
                    Text("Based on: \(location.latitude, specifier: "%.2f"), \(location.longitude, specifier: "%.2f")")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.blue)
                    .font(.title2)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
    
    private func maghribDisplayValue(_ maghrib: PrayerMethodParams.MaghribParam) -> String {
        switch maghrib {
        case .degrees(let degrees):
            return "\(degrees)°"
        case .minutes(let minutes):
            return minutes
        }
    }
}

#Preview {
    let fetcher = PrayerTimesFetcher()
    return CalculationMethodSelectorView(prayerFetcher: fetcher)
}
