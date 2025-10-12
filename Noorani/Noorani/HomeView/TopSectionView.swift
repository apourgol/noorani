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
    @StateObject private var locationManager = LocationManager()
    @State private var showLocationMenu = false
    @AppStorage("currentCity") private var currentCity = ""
    
    private func formatDateFromAdhanAPI(date: String) -> String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "dd MMM yyyy" // Matches "04 Oct 2025"

        guard let parsedDate = inputFormatter.date(from: date) else {
            return date // fallback if parsing fails
        }

        let outputFormatter = DateFormatter()
        outputFormatter.locale = Locale.current
        outputFormatter.dateStyle = .long

        return outputFormatter.string(from: parsedDate)
    }

    
    var body: some View {
        Group {
            VStack(alignment: .leading, spacing: 0) {
                // Remove Spacer and use padding instead
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
                    Button {
                        showLocationMenu = true
                    } label: {
                        HStack(spacing: 4) {
                            if locationManager.isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .foregroundColor(Color(hex: "#fab555"))
                            } else {
                                Image(systemName: "location.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color(hex: "#fab555"))
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
                    .sheet(isPresented: $showLocationMenu) {
                        LocationMenuView(locationManager: locationManager)
                    }
                }
                .padding(.horizontal, 24)
                
                
                // Prayer information - reduced spacing between Next Prayer and Dhuhr
                HStack(alignment: .lastTextBaseline) {
                    VStack(alignment: .leading, spacing: 2) { // Reduced from 4 to 2
                        Text("Next Prayer")
                            .font(.custom("Nunito-Regular", size: 16))
                            .foregroundColor(.black.opacity(0.7))
                        
                        // TODO: update this to be correct prayer
                        Text(prayerFetcher.nextPrayerName)
                            .font(.custom("Nunito-SemiBold", size: 48))
                            .foregroundColor(.black)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                    }
                    
                    Spacer()
                    
                    // TODO: IMPLEMENT COUNTDOWN HERE FOR NEXT PRAYER OR SUNRISE/SUNSET
                    Text(prayerFetcher.countdown)
                        .font(.custom("Nunito-Regular", size: 32))
                        .foregroundColor(.black)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
                .padding(.horizontal, 24)
                .padding(.bottom)
            }
            // current date
            HStack {
                Text(formatDateFromAdhanAPI(date: prayerFetcher.readableDate))
                    .font(.custom("Nunito-Regular", size: 18))
                    .foregroundColor(.black.opacity(0.8))
            }
        }
    }
}

// Extension for hex color support
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    TopSectionView(prayerFetcher: PrayerTimesFetcher())
}
