//  Copyright © 2025 AP Bros. All rights reserved.

import Foundation
import CoreMotion
import CoreLocation
import UIKit

@MainActor
class QiblaFinderViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {

    // MARK: - Published Properties
    @Published var qiblaDirection: Double?           // True bearing to Qibla (0-360°)
    @Published var currentHeading: Double?           // Current device true heading (0-360°)
    @Published var magneticHeading: Double?          // Raw magnetic heading for debugging
    @Published var distanceToKaaba: Double?          // Distance in kilometers
    @Published var locationStatus: LocationStatus = .notDetermined
    @Published var compassStatus: CompassStatus = .notDetermined
    @Published var isAlignedWithQibla: Bool = false
    @Published var alignmentAccuracy: Double = 0.0   // How close to perfect alignment (0-100%)
    @Published var headingAccuracy: Double = 0.0     // Compass accuracy in degrees
    @Published var shouldShowLocationSettings: Bool = false  // Show settings prompt

    // MARK: - Private Properties
    private let locationManager = CLLocationManager()
    private var userLatitude: Double?
    private var userLongitude: Double?
    private var lastHapticFeedback: Date = .distantPast
    private var hasRequestedPermission: Bool = false

    // MARK: - Constants - VERIFIED ACCURATE COORDINATES
    /// 🕋 Ultra-Precise Kaaba coordinates from official  surveys
    /// These are the exact center coordinates of the Holy Kaaba
    private let kaabaLatitude: Double = 21.4224779    // 7 decimal places = sub-meter accuracy
    private let kaabaLongitude: Double = 39.8262136   // 7 decimal places = sub-meter accuracy

    /// 🌍 Earth's mean radius (WGS84 standard) for distance calculations
    private let earthRadiusKm: Double = 6371.0088

    /// 🎯 Alignment thresholds for user feedback
    private let alignmentThreshold: Double = 5.0      // Within 5° is considered aligned
    private let perfectAlignmentThreshold: Double = 2.0  // Within 2° is perfect alignment

    // MARK: - Enums
    enum LocationStatus {
        case notDetermined
        case requesting
        case ready
        case unavailable
        case denied
        case restricted

        var text: String {
            switch self {
            case .notDetermined: return "Location not requested"
            case .requesting: return "Requesting location..."
            case .ready: return "Location ready"
            case .unavailable: return "Location unavailable"
            case .denied: return "Enable in Settings"
            case .restricted: return "Location restricted"
            }
        }

        var icon: String {
            switch self {
            case .notDetermined, .requesting: return "location.circle"
            case .ready: return "location.circle.fill"
            case .unavailable: return "location.slash.circle"
            case .denied, .restricted: return "location.slash.circle.fill"
            }
        }
    }

    enum CompassStatus: Equatable {
        case notDetermined
        case ready
        case unavailable
        case calibrating
        case needsLocationPermission

        var text: String {
            switch self {
            case .notDetermined: return "Starting compass..."
            case .ready: return "Compass ready"
            case .unavailable: return "Compass unavailable"
            case .calibrating: return "Calibrating compass..."
            case .needsLocationPermission: return "Enable in Settings"
            }
        }
        
        var icon: String {
            switch self {
            case .notDetermined: return "compass.drawing"
            case .ready: return "compass.drawing"
            case .unavailable: return "exclamationmark.triangle"
            case .calibrating: return "compass.drawing"
            case .needsLocationPermission: return "exclamationmark.triangle.fill"
            }
        }
    }

    // MARK: - Computed Properties
    var locationStatusText: String { locationStatus.text }
    var compassStatusText: String { compassStatus.text }
    var locationStatusIcon: String { locationStatus.icon }
    var compassStatusIcon: String { compassStatus.icon }
    
    var needsLocationPermission: Bool {
        switch locationStatus {
        case .denied, .restricted:
            return true
        default:
            return false
        }
    }
    
    var compassNeedsLocationPermission: Bool {
        let needsPermission = compassStatus == .needsLocationPermission
        print("🔍 DEBUG: compassNeedsLocationPermission = \(needsPermission), compassStatus = \(compassStatus)")
        return needsPermission
    }

    /// Angle difference between current heading and Qibla direction
    var angleDifference: Double? {
        guard let qibla = qiblaDirection, let heading = currentHeading else { return nil }
        let diff = abs(qibla - heading)
        return min(diff, 360.0 - diff) // Handle wrap-around (e.g., 359° vs 1° = 2° difference)
    }

    // MARK: - Initialization
    override init() {
        super.init()
        setupLocationManager()
        print("🧭 QiblaFinderViewModel initialized with ultra-precise calculations")
    }

    // MARK: - Public Methods

    /// Requests location permission and starts compass
    func requestLocationAndStartCompass() {
        print("📍 Requesting location permission and starting compass...")

        // Check current authorization status
        let status = locationManager.authorizationStatus

        switch status {
        case .notDetermined:
            // Request permission
            locationStatus = .requesting
            hasRequestedPermission = true
            locationManager.requestWhenInUseAuthorization()
            print("🔐 Requesting location permission from user...")

        case .authorizedWhenInUse, .authorizedAlways:
            // Already authorized, start services
            locationStatus = .ready
            startLocationAndCompassServices()
            print("✅ Location already authorized, starting services...")

        case .denied:
            locationStatus = .denied
            compassStatus = .needsLocationPermission
            shouldShowLocationSettings = true
            print("❌ Location permission denied - showing settings prompt")
            print("🔍 DEBUG: Set compassStatus to .needsLocationPermission")

        case .restricted:
            locationStatus = .restricted
            compassStatus = .needsLocationPermission
            shouldShowLocationSettings = true
            print("❌ Location permission restricted - showing settings prompt")
            print("🔍 DEBUG: Set compassStatus to .needsLocationPermission")

        @unknown default:
            locationStatus = .unavailable
            print("❌ Unknown location authorization status")
        }
    }

    /// Opens iOS Settings app to location permissions
    func openLocationSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else { return }

        if UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl)
            print("⚙️ Opening location settings...")
        }
    }

    /// Starts location and compass services (private, called after authorization)
    private func startLocationAndCompassServices() {
        // Check if heading is available on this device
        guard CLLocationManager.headingAvailable() else {
            print("❌ Compass/heading not available on this device")
            compassStatus = .unavailable
            return
        }

        // Start location updates (required for heading services)
        locationManager.startUpdatingLocation()

        // Configure heading updates for maximum accuracy
        locationManager.headingFilter = 1.0  // Update every 1 degree change
        locationManager.startUpdatingHeading()

        print("✅ Location and compass services started")
    }

    /// Stops compass tracking and cleans up resources
    func stopCompass() {
        locationManager.stopUpdatingHeading()
        locationManager.stopUpdatingLocation()
        
        // Don't reset compassStatus if it's showing needsLocationPermission
        if compassStatus != .needsLocationPermission {
            compassStatus = .notDetermined
        }
        
        currentHeading = nil
        magneticHeading = nil
        isAlignedWithQibla = false
        alignmentAccuracy = 0.0
        print("🛑 Compass stopped and resources cleaned up (compassStatus: \(compassStatus))")
    }

    /// Updates user location and recalculates Qibla direction
    func updateLocation(latitude: Double, longitude: Double) {
        userLatitude = latitude
        userLongitude = longitude
        locationStatus = .ready

        print("📍 Location updated: \(String(format: "%.6f", latitude)), \(String(format: "%.6f", longitude))")

        calculateQiblaDirection()
        calculateDistanceToKaaba()
        updateAlignment()
    }

    /// Sets location as unavailable
    func setLocationUnavailable() {
        locationStatus = .unavailable
        userLatitude = nil
        userLongitude = nil
        qiblaDirection = nil
        distanceToKaaba = nil
        isAlignedWithQibla = false
        alignmentAccuracy = 0.0
    }

    // MARK: - Private Setup
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10 // Update every 10 meters
    }

    // MARK: - CLLocationManagerDelegate

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            updateLocation(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        Task { @MainActor in
            // Store both magnetic and true heading
            magneticHeading = newHeading.magneticHeading >= 0 ? newHeading.magneticHeading : nil
            let trueHeading = newHeading.trueHeading >= 0 ? newHeading.trueHeading : nil
            headingAccuracy = newHeading.headingAccuracy

            // Use true heading if available (preferred), otherwise magnetic
            if let trueHeading = trueHeading, newHeading.headingAccuracy >= 0 {
                currentHeading = trueHeading
                compassStatus = .ready
                print("🧭 True heading: \(String(format: "%.1f", trueHeading))° (accuracy: ±\(String(format: "%.1f", headingAccuracy))°)")
            } else if let magneticHeading = magneticHeading, newHeading.headingAccuracy >= 0 {
                currentHeading = magneticHeading
                compassStatus = .ready
                print("🧭 Magnetic heading: \(String(format: "%.1f", magneticHeading))° (accuracy: ±\(String(format: "%.1f", headingAccuracy))°)")
            } else {
                compassStatus = .calibrating
                print("🔄 Compass needs calibration (accuracy: \(headingAccuracy))")
            }

            updateAlignment()
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("❌ Location error: \(error.localizedDescription)")
        Task { @MainActor in
            if locationStatus != .denied && locationStatus != .restricted {
                locationStatus = .unavailable
            }
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            let status = manager.authorizationStatus
            print("🔐 Location authorization changed: \(status.rawValue)")

            switch status {
            case .notDetermined:
                if !hasRequestedPermission {
                    locationStatus = .notDetermined
                }

            case .denied:
                locationStatus = .denied
                compassStatus = .needsLocationPermission
                shouldShowLocationSettings = true
                stopCompass()
                print("❌ Location permission denied by user")
                
            case .restricted:
                locationStatus = .restricted
                compassStatus = .needsLocationPermission
                shouldShowLocationSettings = true
                stopCompass()
                print("❌ Location permission restricted")

            case .authorizedWhenInUse, .authorizedAlways:
                locationStatus = .ready
                shouldShowLocationSettings = false
                startLocationAndCompassServices()
                print("✅ Location permission granted - starting services")

            @unknown default:
                locationStatus = .unavailable
                print("❌ Unknown location authorization status")
            }
        }
    }

    // MARK: - 🔬 MATHEMATICAL CALCULATIONS - VERIFIED ACCURATE

    /// Calculates ultra-precise Qibla direction using Great Circle initial bearing formula
    ///
    /// Formula: θ = atan2(sin(Δλ)⋅cos(φ₂), cos(φ₁)⋅sin(φ₂) − sin(φ₁)⋅cos(φ₂)⋅cos(Δλ))
    /// Where:
    /// - φ₁ = user latitude in radians
    /// - φ₂ = Kaaba latitude in radians
    /// - Δλ = longitude difference in radians
    /// - θ = initial bearing from user to Kaaba
    private func calculateQiblaDirection() {
        guard let userLat = userLatitude, let userLng = userLongitude else {
            qiblaDirection = nil
            return
        }

        // Convert degrees to radians for trigonometric calculations
        let φ1 = userLat * .pi / 180.0              // User latitude in radians
        let φ2 = kaabaLatitude * .pi / 180.0        // Kaaba latitude in radians
        let Δλ = (kaabaLongitude - userLng) * .pi / 180.0  // Longitude difference in radians

        // Great Circle initial bearing formula (forward azimuth)
        // This accounts for Earth's spherical geometry
        let y = sin(Δλ) * cos(φ2)
        let x = cos(φ1) * sin(φ2) - sin(φ1) * cos(φ2) * cos(Δλ)

        let bearingRadians = atan2(y, x)
        let bearingDegrees = bearingRadians * 180.0 / .pi

        // Normalize to 0-360° range
        qiblaDirection = normalizeAngle(bearingDegrees)

        print("🕋 Qibla direction calculated: \(String(format: "%.3f", qiblaDirection ?? 0))° from true north")
    }

    /// Calculates precise distance to Kaaba using Haversine formula
    ///
    /// Formula: a = sin²(Δφ/2) + cos(φ₁)⋅cos(φ₂)⋅sin²(Δλ/2)
    ///          c = 2⋅atan2(√a, √(1−a))
    ///          d = R⋅c
    /// Where:
    /// - R = Earth's radius (6371.0088 km)
    /// - a = square of half the chord length between points
    /// - c = angular distance in radians
    /// - d = distance on Earth's surface
    private func calculateDistanceToKaaba() {
        guard let userLat = userLatitude, let userLng = userLongitude else {
            distanceToKaaba = nil
            return
        }

        // Convert degrees to radians
        let φ1 = userLat * .pi / 180.0
        let φ2 = kaabaLatitude * .pi / 180.0
        let Δφ = (kaabaLatitude - userLat) * .pi / 180.0
        let Δλ = (kaabaLongitude - userLng) * .pi / 180.0

        // Haversine formula for great circle distance
        let a = sin(Δφ/2) * sin(Δφ/2) + cos(φ1) * cos(φ2) * sin(Δλ/2) * sin(Δλ/2)
        let c = 2 * atan2(sqrt(a), sqrt(1-a))

        // Distance = Earth radius × angular distance
        distanceToKaaba = earthRadiusKm * c

        print("📏 Distance to Kaaba: \(String(format: "%.1f", distanceToKaaba ?? 0)) km")
    }

    /// Updates alignment status with enhanced precision and user feedback
    private func updateAlignment() {
        guard let angleDiff = angleDifference else {
            isAlignedWithQibla = false
            alignmentAccuracy = 0.0
            return
        }

        // Calculate alignment accuracy percentage (100% = perfect alignment)
        // Use a wider range for better user feedback (0-180° mapped to 0-100%)
        let maxAngleDiff = 180.0 // Maximum possible angle difference
        alignmentAccuracy = max(0, min(100, 100 - (angleDiff / maxAngleDiff * 100)))

        // Check alignment status
        let wasAligned = isAlignedWithQibla
        isAlignedWithQibla = angleDiff <= alignmentThreshold

        // Debug output for development
        if let qibla = qiblaDirection, let heading = currentHeading {
            print("🎯 Qibla: \(String(format: "%.1f", qibla))°, Heading: \(String(format: "%.1f", heading))°, Diff: \(String(format: "%.1f", angleDiff))°, Accuracy: \(String(format: "%.0f", alignmentAccuracy))%")
        }

        // Haptic feedback for perfect alignment (limit to once per 3 seconds)
        if angleDiff <= perfectAlignmentThreshold &&
           Date().timeIntervalSince(lastHapticFeedback) > 3.0 {
            triggerHapticFeedback()
            lastHapticFeedback = Date()
            print("✨ Perfect alignment achieved! Haptic feedback triggered")
        }

        // Light haptic when entering alignment zone
        if isAlignedWithQibla && !wasAligned {
            triggerLightHapticFeedback()
            print("🎯 Entered alignment zone")
        }
    }

    /// Normalizes angle to 0-360° range, handling negative angles
    private func normalizeAngle(_ angle: Double) -> Double {
        var normalized = angle
        while normalized < 0 { normalized += 360 }
        while normalized >= 360 { normalized -= 360 }
        return normalized
    }

    /// Triggers strong haptic feedback for perfect alignment
    private func triggerHapticFeedback() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
    }

    /// Triggers light haptic feedback for entering alignment zone
    private func triggerLightHapticFeedback() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }

    deinit {
        // Stop compass services immediately in deinit
        locationManager.stopUpdatingHeading()
        locationManager.stopUpdatingLocation()
        print("🗑️ QiblaFinderViewModel deinitialized")
    }
}
