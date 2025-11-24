//
//  LocationUtils.swift
//  Noorani
//  Copyright © 2025 AP Bros. All rights reserved.
//

import Foundation
import CoreLocation

/// Utility functions for location calculations
struct LocationUtils {

    /// Calculate the distance between two coordinates using the Haversine formula
    /// - Parameters:
    ///   - lat1: First latitude in degrees
    ///   - lon1: First longitude in degrees
    ///   - lat2: Second latitude in degrees
    ///   - lon2: Second longitude in degrees
    /// - Returns: Distance in kilometers
    static func calculateDistance(
        lat1: Double,
        lon1: Double,
        lat2: Double,
        lon2: Double
    ) -> Double {
        // Earth's radius in kilometers
        let earthRadius = 6371.0

        // Convert degrees to radians
        let dLat = (lat2 - lat1) * .pi / 180.0
        let dLon = (lon2 - lon1) * .pi / 180.0
        let lat1Rad = lat1 * .pi / 180.0
        let lat2Rad = lat2 * .pi / 180.0

        // Haversine formula
        let a = sin(dLat / 2) * sin(dLat / 2) +
                sin(dLon / 2) * sin(dLon / 2) *
                cos(lat1Rad) * cos(lat2Rad)
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))

        return earthRadius * c
    }

    /// Check if the distance between two locations exceeds a threshold
    /// - Parameters:
    ///   - oldLat: Previous latitude
    ///   - oldLon: Previous longitude
    ///   - newLat: New latitude
    ///   - newLon: New longitude
    ///   - thresholdKm: Threshold distance in kilometers (default: 1.6km / 1 mile)
    /// - Returns: True if distance exceeds threshold
    static func hasLocationChangedSignificantly(
        oldLat: Double,
        oldLon: Double,
        newLat: Double,
        newLon: Double,
        thresholdKm: Double = 1.6
    ) -> Bool {
        let distance = calculateDistance(
            lat1: oldLat,
            lon1: oldLon,
            lat2: newLat,
            lon2: newLon
        )
        return distance > thresholdKm
    }
}
