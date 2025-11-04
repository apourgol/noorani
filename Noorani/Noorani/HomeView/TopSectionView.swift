//
//  TopSectionView.swift
//  Noorani
//
//  Created by neo on 9/29/25.
//  Copyright © 2025 AP Bros. All rights reserved.
//

import SwiftUI

struct TopSectionView: View {
    @ObservedObject var prayerFetcher: PrayerTimesFetcher
    @ObservedObject var locationManager: LocationManager
    @StateObject private var viewModel: TopSectionViewModel
    
    // Custom initializer to inject dependencies
    init(prayerFetcher: PrayerTimesFetcher, locationManager: LocationManager) {
        self.prayerFetcher = prayerFetcher
        self.locationManager = locationManager
        self._viewModel = StateObject(wrappedValue: TopSectionViewModel(
            prayerTimesFetcher: prayerFetcher,
            locationManager: locationManager
        ))
    }
    
    var body: some View {
        Group {
            VStack(alignment: .leading, spacing: 0) {
                // Sun logo on left, location indicator on right
                HStack(alignment: .center) {
                    // Sun logo - fixed size for all devices, make it bigger on iPad (180) vs 120
                    let isPad = UIDevice.current.userInterfaceIdiom == .pad
                    let sunLogoSize: CGFloat = isPad ? 300 : 150
                    // TODO: update the logo for prayer with respective prayer
                    // TODO: shrink space between sunlogo and next prayer
                    Image("SunLogo")
                        .resizable()
                        .scaledToFit()
                        .shadow(radius: 4.0, y: 5)
                        .frame(width: sunLogoSize, height: sunLogoSize)
                        .layoutPriority(1)
                    
                    Spacer()
                    
                    // Location button - shows dynamic city name
                    LocationButton(
                        currentCity: viewModel.currentCity,
                        isLoading: viewModel.isLocationLoading,
                        action: viewModel.showLocationMenuAction
                    )
                }
                .padding(.horizontal, 24)
                
                // Prayer information - reduced spacing between Next Prayer and Dhuhr
                PrayerInfoSection(
                    nextEventLabel: viewModel.getNextEventLabel(viewModel.nextPrayerName),
                    nextPrayerName: viewModel.nextPrayerName,
                    countdown: viewModel.countdown
                )
                .padding(.horizontal, 24)
                .padding(.bottom)
            }
            
            // current date
            HStack {
                Text(viewModel.formatDateFromAdhanAPI(date: viewModel.readableDate))
                    .font(.custom("Nunito-Regular", size: 18))
                    .foregroundColor(.nooraniTextSecondary)
            }
        }
        .sheet(isPresented: $viewModel.showLocationMenu) {
            LocationMenuView(locationManager: locationManager)
        }
    }
}

// MARK: - Location Button Component
struct LocationButton: View {
    let currentCity: String
    let isLoading: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .foregroundColor(.nooraniPrimary)
                } else {
                    Image(systemName: "location.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.nooraniPrimary)
                }
                
                Text(currentCity)
                    .font(.custom("Nunito-Light", size: 15))
                    .foregroundColor(.black.opacity(0.8))
                    .lineLimit(1)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(hex: "#fddaaa"))
            .cornerRadius(16)
        }
    }
}

// MARK: - Prayer Info Section Component
struct PrayerInfoSection: View {
    let nextEventLabel: String
    let nextPrayerName: String
    let countdown: String
    
    var body: some View {
        HStack(alignment: .lastTextBaseline) {
            VStack(alignment: .leading, spacing: 2) { // Reduced from 4 to 2
                // Show "Next Prayer" or "Next Event" based on what's next
                Text(nextEventLabel)
                    .font(.custom("Nunito-Regular", size: 16))
                    .foregroundColor(.nooraniTextSecondary)
                
                // TODO: update this to be correct prayer
                Text(nextPrayerName)
                    .font(.custom("Nunito-SemiBold", size: 48))
                    .foregroundColor(.nooraniTextPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
            
            Spacer()
            
            // TODO: IMPLEMENT COUNTDOWN HERE FOR NEXT PRAYER OR SUNRISE/SUNSET
            Text(countdown)
                .font(.custom("Nunito-Regular", size: 32))
                .foregroundColor(.nooraniTextPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
    }
}

#Preview {
    TopSectionView(
        prayerFetcher: PrayerTimesFetcher(),
        locationManager: LocationManager()
    )
}
