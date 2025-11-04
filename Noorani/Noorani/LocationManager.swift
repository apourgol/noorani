//
//  LocationManager.swift
//  Noorani
//
//  Created by Amin Pourgol on 10/4/25.
//  Copyright © 2025 AP Bros. All rights reserved.
//


import CoreLocation
import SwiftUI

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private lazy var locationManager: CLLocationManager = {
        let manager = CLLocationManager()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        return manager
    }()
    @AppStorage("currentCity") private var currentCity = ""
    @AppStorage("currentLat") private var currentLat: Double = 0
    @AppStorage("currentLng") private var currentLng: Double = 0
    
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var isLoading = false
    
    @Published var latitude: Double?
    @Published var longitude: Double?


    override init() {
        super.init()
        // locationManager is now lazy, so it won't be created until first accessed
    }

    func requestLocation(completion: @escaping () -> Void) {
        isLoading = true

        switch authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
            // Call completion later when authorization changes
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.requestLocation()
            completion()
        case .denied, .restricted:
            isLoading = false
            print("Location access denied")
            completion()
        @unknown default:
            isLoading = false
            completion()
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
        
        // Save coordinates
        latitude = location.coordinate.latitude
        currentLat = location.coordinate.latitude
        longitude = location.coordinate.longitude
        currentLng = location.coordinate.longitude

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

    func getCoordinates(for city: String, completion: @escaping (CLLocationCoordinate2D?) -> Void) {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(city) { placemarks, error in
            if let error = error {
                print("Geocoding error: \(error.localizedDescription)")
                completion(nil)
                return
            }

            if let location = placemarks?.first?.location {
                completion(location.coordinate)
            } else {
                completion(nil)
            }
        }
    }

}
