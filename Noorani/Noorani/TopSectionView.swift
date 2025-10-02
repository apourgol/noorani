//
//  TopSectionView.swift
//  Noorani
//
//  Created by neo on 9/29/25.
//

import SwiftUI
import CoreLocation

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var currentCity = "Location" // Default city, we can set this to anything
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var isLoading = false

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func requestLocation() {
        isLoading = true

        switch authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.requestLocation()
        case .denied, .restricted:
            isLoading = false
            print("Location access denied")
        @unknown default:
            isLoading = false
        }
    }

    func updateCity(to city: String) {
        currentCity = city
    }

    // MARK: - CLLocationManagerDelegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus

        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            locationManager.requestLocation()
        } else if authorizationStatus == .denied || authorizationStatus == .restricted {
            isLoading = false
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else {
            isLoading = false
            return
        }

        // Reverse geocode to get city name -> TODO: INTEGRATE PRAYER TIMES API BASED ON LOCATION!
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            DispatchQueue.main.async {
                self?.isLoading = false

                if let error = error {
                    print("Reverse geocoding error: \(error.localizedDescription)")
                    return
                }

                if let placemark = placemarks?.first {
                    let city = placemark.locality ?? "Unknown City"
                    let state = placemark.administrativeArea ?? ""

                    self?.currentCity = state.isEmpty ? city : "\(city), \(state)"
                    print("Location updated to: \(self?.currentCity ?? "")")
                }
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        isLoading = false
        print("Location error: \(error.localizedDescription)")
    }
}

struct TopSectionView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var showLocationMenu = false

    private var currentDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd, yyyy"
        return formatter.string(from: Date())
    }

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                ZStack(alignment: .topLeading) {
                    // gradient: #fab555 → #feecd3 → white
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: Color(hex: "#fab555"), location: 0.0), // Yellow/orange
                            .init(color: Color(hex: "#feecd3"), location: 0.6), // Light cream
                            .init(color: Color.white, location: 1.0)  // White
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: geometry.size.height * 0.55)
                    .ignoresSafeArea(.all, edges: .top)

                    VStack(alignment: .leading, spacing: 0) {
                        // Remove Spacer and use padding instead
                        // Sun logo on left, location indicator on right
                        HStack(alignment: .center) {
                            // Sun logo - fixed size for all devices, make it bigger on iPad (180) vs 120
                            let isPad = UIDevice.current.userInterfaceIdiom == .pad
                            let sunLogoSize: CGFloat = isPad ? 180 : 120
                            // TODO: update the logo for prayer with respective prayer
                            // TODO: shrink space between sunlogo and next prayer
                            Image("SunLogo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: sunLogoSize, height: sunLogoSize)
                                .layoutPriority(1)

                            Spacer()

                            // Location button - shows dynamic city name
                            Button(action: {
                                showLocationMenu = true
                            }) {
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

                                    Text(locationManager.currentCity)
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

                        Spacer().frame(height: 50)

                        // Prayer information - reduced spacing between Next Prayer and Dhuhr
                        HStack(alignment: .lastTextBaseline) {
                            VStack(alignment: .leading, spacing: 2) { // Reduced from 4 to 2
                                Text("Next Prayer")
                                    .font(.custom("Nunito-Regular", size: 16))
                                    .foregroundColor(.black.opacity(0.7))

                                // TODO: update this to be correct prayer
                                Text("Dhuhr")
                                    .font(.custom("Nunito-SemiBold", size: min(48, geometry.size.width * 0.12)))
                                    .foregroundColor(.black)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.5)
                            }

                            Spacer()

                            // TODO: IMPLEMENT COUNTDOWN HERE FOR NEXT PRAYER OR SUNRISE/SUNSET
                            Text("0:23:46")
                                .font(.custom("Nunito-Regular", size: min(32, geometry.size.width * 0.08)))
                                .foregroundColor(.black)
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)
                        }
                        .padding(.horizontal, 24)

                        Spacer().frame(height: 30)

                        // current date
                        HStack {
                            Spacer()
                            Text(currentDate)
                                .font(.custom("Nunito-Regular", size: 18))
                                .foregroundColor(.black.opacity(0.8))
                            Spacer()
                        }
                        .padding(.bottom, 40) // Increased bottom spacing
                    }
                    .padding(.top, geometry.safeAreaInsets.top + 80)
                }

                // Rest of the screen remains white
                Spacer()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.white)
            }
        }
    }
}

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
                        locationManager.requestLocation()
                        dismiss()
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
                        .padding(.horizontal, 20)
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
    ContentView()
}
