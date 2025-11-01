//
//  QuickTestView.swift
//  Noorani
//
//  Created by Amin Pourgol on 11/1/25.
//  Copyright © 2025 AP Bros. All rights reserved.
//

import SwiftUI

struct QuickTestView: View {
    @StateObject private var fetcher = PrayerTimesFetcher()
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Prayer Time Calculator Test")
                .font(.title)
                .padding()
            
            if let selectedMethod = fetcher.selectedMethod {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Current Method:")
                        .font(.headline)
                    Text(selectedMethod.name)
                        .font(.body)
                    Text("ID: \(selectedMethod.id)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }
            
            Text("Available Methods: \(fetcher.availableMethods.count)")
                .font(.subheadline)
            
            if fetcher.availableMethods.count > 0 {
                Text("✅ Methods loaded successfully")
                    .foregroundColor(.green)
            } else {
                Text("❌ No methods loaded")
                    .foregroundColor(.red)
            }
            
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(fetcher.availableMethods.prefix(5), id: \.id) { method in
                        HStack {
                            Text(method.name)
                                .font(.caption)
                            Spacer()
                            Text("ID: \(method.id)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .frame(maxHeight: 200)
            
            Spacer()
        }
        .padding()
    }
}

#Preview {
    QuickTestView()
}