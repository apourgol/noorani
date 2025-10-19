//
//  LocationMenuView.swift
//  Noorani
//
//  Created by Amin Pourgol on 10/4/25.
//  Copyright © 2025 AP Bros. All rights reserved.
//

import SwiftUI

struct LocationMenuView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var locationManager: LocationManager
    @State private var searchText = ""
    
    private let popularCities = [
        "New York, NY", "Los Angeles, CA", "Chicago, IL", "Houston, TX",
        "Fairfax, VA", "Philadelphia, PA", "Washington, D.C.", "San Diego, CA",
        "Dallas, TX", "Dearborn, MI", "Austin, TX", "Toronto, CA"
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header with icon and description
                    VStack(spacing: 12) {
                        Image(systemName: "location.circle")
                            .font(.system(size: 48))
                            .foregroundColor(Color(hex: "#fab555"))
                        
                        Text("Choose Your Location")
                            .font(.custom("Nunito-SemiBold", size: 24))
                            .foregroundColor(.black)
                        
                        Text("Select your location to get accurate prayer times")
                            .font(.custom("Nunito-Regular", size: 16))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                    .padding(.top, 20)
                    
                    // Current Location Option - Enhanced Design
                    Button(action: {
                        locationManager.requestLocation() {
                            dismiss()
                        }
                    }) {
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(Color(hex: "#fab555").opacity(0.1))
                                    .frame(width: 50, height: 50)
                                
                                Image(systemName: "location.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(Color(hex: "#fab555"))
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Use Current Location")
                                    .font(.custom("Nunito-SemiBold", size: 18))
                                    .foregroundColor(.black)
                                Text("Automatically detect your location")
                                    .font(.custom("Nunito-Regular", size: 14))
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                            
                            if locationManager.isLoading {
                                ProgressView()
                                    .scaleEffect(1.0)
                                    .foregroundColor(Color(hex: "#fab555"))
                            } else {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.gray.opacity(0.6))
                            }
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white)
                                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color(hex: "#fab555").opacity(0.2), lineWidth: 1)
                        )
                    }
                    .disabled(locationManager.isLoading)
                    .padding(.horizontal, 20)
                    
                    // Search Bar - Enhanced Design
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Search for a City")
                            .font(.custom("Nunito-SemiBold", size: 18))
                            .foregroundColor(.black)
                            .padding(.horizontal, 20)
                        
                        HStack(spacing: 10) {
                            HStack(spacing: 12) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 18))
                                    .foregroundColor(.gray.opacity(0.6))
                                
                                TextField("Enter city name...", text: $searchText)
                                    .font(.custom("Nunito-Regular", size: 16))
                                    .onSubmit {
                                        if !searchText.isEmpty {
                                            locationManager.updateCity(to: searchText)
                                            dismiss()
                                        }
                                    }
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.gray.opacity(0.05))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                    )
                            )
                            
                            Button {
                                if !searchText.isEmpty {
                                    locationManager.updateCity(to: searchText)
                                    dismiss()
                                }
                            } label: {
                                RoundedRectangle(cornerRadius: 20)
                                    .foregroundStyle(Color.blue)
                                    .overlay {
                                        Text("Search")
                                            .font(Font.custom("Nunito-SemiBold", size: 16))
                                            .foregroundStyle(Color.white)
                                    }
                            }
                            .frame(width: 75)
                        }
                        .padding(.horizontal)
                    }
                    
                    // Popular Cities
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Popular Cities")
                            .font(.custom("Nunito-SemiBold", size: 18))
                            .foregroundColor(.black)
                            .padding(.horizontal, 20)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12)
                        ], spacing: 12) {
                            ForEach(popularCities, id: \.self) { city in
                                Button(action: {
                                    locationManager.updateCity(to: city)
                                    dismiss()
                                }) {
                                    Text(city)
                                        .font(.custom("Nunito-Regular", size: 15))
                                        .foregroundColor(.black)
                                        .multilineTextAlignment(.center)
                                        .padding(.vertical, 16)
                                        .padding(.horizontal, 12)
                                        .frame(maxWidth: .infinity, minHeight: 50)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color.white)
                                                .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 1)
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                                        )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    Spacer(minLength: 20)
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.custom("Nunito-SemiBold", size: 16))
                    .foregroundColor(Color(hex: "#fab555"))
                }
            }
        }
        .presentationDetents([.height(650), .large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(24)
        .presentationBackground(Color(UIColor.systemGroupedBackground))
    }
}
