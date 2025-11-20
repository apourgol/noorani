//  Copyright © 2025 AP Bros. All rights reserved.

import SwiftUI
import CoreLocation
import CoreMotion

/// 🧭 DEFINITIVE Ultra-Accurate Qibla Finder View
/// Beautiful design with Noorani brand colors and professional UI/UX
struct QiblaFinderView: View {
    @StateObject private var qiblaFinder = QiblaFinderViewModel()
    @ObservedObject var locationManager: LocationManager

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                // 🎨 Noorani Brand Gradient Background (consistent with other pages)
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color.nooraniPrimary, location: 0.0),      // #fab555 - Golden
                        .init(color: Color.nooraniSecondary, location: 0.55),   // #feecd3 - Light cream
                        .init(color: Color.nooraniBackground, location: 1.0)    // White
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea(.all, edges: .vertical)

                ScrollView {
                    VStack(spacing: 30) {
                        // MARK: - 🕋 Header Section
                        VStack(spacing: 15) {
                            // Kaaba Icon with glow effect
                            Image("makkah")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 60, height: 60)
                                .foregroundColor(Color.nooraniPrimary)
                                .shadow(color: Color.nooraniPrimary.opacity(0.3), radius: 8, x: 0, y: 0)
                                .padding(.bottom, 15)
                                .padding(.top, 10)

                            Text("Qibla Finder")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(Color.nooraniTextPrimary)

                            if qiblaFinder.isAlignedWithQibla {
                                Text("Perfectly Aligned with the Holy Kaaba")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.green)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                                    .background(Color.green.opacity(0.1))
                                    .cornerRadius(25)
                                    .lineLimit(1)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 25)
                                            .stroke(Color.green.opacity(0.3), lineWidth: 1)
                                    )
                            } else {
                                Text("Point your device towards Makkah")
                                    .font(.subheadline)
                                    .foregroundColor(Color.nooraniTextSecondary)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding(.top, 20)
                        .padding(.horizontal, 20)

                        // MARK: - 📊 Status Cards
                        HStack(spacing: 15) {
                            StatusCard(
                                icon: qiblaFinder.locationStatusIcon,
                                title: "Location",
                                status: qiblaFinder.locationStatusText,
                                isReady: qiblaFinder.locationStatus == .ready,
                                isDenied: qiblaFinder.needsLocationPermission
                            )
                            
                            StatusCard(
                                icon: qiblaFinder.compassStatusIcon,
                                title: "Compass", 
                                status: qiblaFinder.compassStatusText,
                                isReady: qiblaFinder.compassStatus == .ready,
                                isDenied: qiblaFinder.compassNeedsLocationPermission
                            )
                        }
                        .padding(.horizontal, 20)

                        // MARK: - 🧭 Main Compass Container
                        VStack(spacing: 25) {
                            // Ultra-Accurate Compass Circle
                            ZStack {
                                // Outer Ring with Smart Alignment Indicator
                                Circle()
                                    .stroke(
                                        qiblaFinder.isAlignedWithQibla ?
                                        Color.green.opacity(0.8) : Color.nooraniPrimary.opacity(0.4),
                                        lineWidth: 8
                                    )
                                    .frame(width: min(geometry.size.width - 40, 340))
                                    .overlay(
                                        // Dynamic glow effect
                                        Circle()
                                            .stroke(
                                                qiblaFinder.isAlignedWithQibla ?
                                                Color.green.opacity(0.4) : Color.nooraniPrimary.opacity(0.2),
                                                lineWidth: 16
                                            )
                                            .blur(radius: 8)
                                    )
                                    .scaleEffect(qiblaFinder.isAlignedWithQibla ? 1.05 : 1.0)
                                    .animation(.easeInOut(duration: 0.5), value: qiblaFinder.isAlignedWithQibla)

                                // Inner Compass Background with subtle shadow
                                Circle()
                                    .fill(Color.nooraniCardBackground)
                                    .frame(width: min(geometry.size.width - 70, 310))
                                    .shadow(color: Color.nooraniShadow, radius: 15, x: 0, y: 8)

                                // Professional Compass Rose that rotates like a real compass
                                CompassRoseView(currentHeading: qiblaFinder.currentHeading)
                                    .frame(width: min(geometry.size.width - 100, 280))

                                // Ultra-Precise Qibla Arrow
                                QiblaArrowView(
                                    qiblaDirection: qiblaFinder.qiblaDirection,
                                    currentHeading: qiblaFinder.currentHeading,
                                    isAligned: qiblaFinder.isAlignedWithQibla,
                                    alignmentAccuracy: qiblaFinder.alignmentAccuracy
                                )
                                .frame(width: min(geometry.size.width - 140, 240))

                                // Center Dot with Noorani branding
                                Circle()
                                    .fill(Color.nooraniPrimary)
                                    .frame(width: 20, height: 20)
                                    .shadow(color: Color.nooraniShadow, radius: 4)
                                    .overlay(
                                        Circle()
                                            .fill(Color.white)
                                            .frame(width: 8, height: 8)
                                    )
                            }

                            // Smart Alignment Status with Progress
                            AlignmentStatusView(
                                isAligned: qiblaFinder.isAlignedWithQibla,
                                accuracy: qiblaFinder.alignmentAccuracy,
                                angleDifference: qiblaFinder.angleDifference
                            )
                        }
                        .padding(.horizontal, 20)

                        // MARK: - 📈 Precision Information Cards
                        VStack(spacing: 15) {
                            if let distance = qiblaFinder.distanceToKaaba {
                                InfoCard(
                                    icon: "ruler",
                                    title: "Distance to Holy Kaaba",
                                    value: String(format: "%.1f km", distance),
                                    subtitle: "Straight line distance"
                                )
                            }

                            if let direction = qiblaFinder.qiblaDirection {
                                InfoCard(
                                    icon: "location.north.fill",
                                    title: "Qibla Direction",
                                    value: String(format: "%.2f°", direction),
                                    subtitle: "From true north"
                                )
                            }

                            if let heading = qiblaFinder.currentHeading {
                                InfoCard(
                                    icon: "gyroscope",
                                    title: "Device Heading",
                                    value: String(format: "%.2f°", heading),
                                    subtitle: "Current direction"
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    }
                }
            }
        }
        .onAppear {
            setupQiblaFinder()
        }
        .onDisappear {
            qiblaFinder.stopCompass()
        }
        .onChange(of: locationManager.latitude) { _, _ in
            updateLocationIfAvailable()
        }
        .onChange(of: locationManager.longitude) { _, _ in
            updateLocationIfAvailable()
        }
        .alert("Location Access Required", isPresented: $qiblaFinder.shouldShowLocationSettings) {
            Button("Open Settings") {
                qiblaFinder.openLocationSettings()
            }
            Button("Cancel", role: .cancel) {
                qiblaFinder.shouldShowLocationSettings = false
            }
        } message: {
            Text("Please enable location access in Settings to use the Qibla finder and determine the direction to Makkah.")
        }
    }

    // MARK: - Helper Methods
    private func setupQiblaFinder() {
        qiblaFinder.requestLocationAndStartCompass()
        updateLocationIfAvailable()
    }

    private func updateLocationIfAvailable() {
        if let lat = locationManager.latitude, let lng = locationManager.longitude {
            qiblaFinder.updateLocation(latitude: lat, longitude: lng)
        } else {
            // Request location if not available
            locationManager.requestLocation {}
        }
    }
}

// MARK: - 📊 Status Card Component
struct StatusCard: View {
    let icon: String
    let title: String
    let status: String
    let isReady: Bool
    let isDenied: Bool

    var body: some View {
        let _ = print("🎨 StatusCard '\(title)': icon=\(icon), status=\(status), isReady=\(isReady), isDenied=\(isDenied)")
        
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(isDenied ? .red : (isReady ? .green : Color.nooraniPrimary))
                .symbolEffect(.pulse, isActive: !isReady && !isDenied)

            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(Color.nooraniTextPrimary)

            Text(status)
                .font(.caption2)
                .foregroundColor(isDenied ? .red : Color.nooraniTextSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(Color.nooraniCardBackground.opacity(0.9))
        .cornerRadius(15)
        .shadow(color: Color.nooraniShadow, radius: 8, x: 0, y: 4)
    }
}

// MARK: - 🧭 Professional Compass Rose Component (Rotates like a real compass)
struct CompassRoseView: View {
    let currentHeading: Double?
    let directions = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]

    // Compass rotation: North should always point to geographic north
    // So we rotate the compass ring opposite to the device heading
    private var compassRotation: Double {
        guard let heading = currentHeading else { return 0 }
        return -heading // Negative to counter-rotate against device heading
    }

    var body: some View {
        ZStack {
            // Outer compass ticks and numbers
            ForEach(0..<36, id: \.self) { index in
                let angle = Double(index) * 10.0
                let isMajorTick = index % 9 == 0 // Every 90 degrees (N, E, S, W)
                let isMinorTick = index % 3 == 0 && !isMajorTick // Every 30 degrees

                VStack(spacing: 2) {
                    if isMajorTick {
                        // Major cardinal directions (N, E, S, W)
                        let directionIndex = index / 9
                        let cardinalDirections = ["N", "E", "S", "W"]
                        Text(cardinalDirections[directionIndex])
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(Color.nooraniTextPrimary)
                            .padding(.bottom, 4)

                        Rectangle()
                            .fill(Color.nooraniPrimary)
                            .frame(width: 3, height: 20)
                    } else if isMinorTick {
                        // Minor ticks every 30 degrees
                        Rectangle()
                            .fill(Color.nooraniTextSecondary.opacity(0.7))
                            .frame(width: 2, height: 12)
                            .padding(.top, 24)
                    } else {
                        // Small ticks every 10 degrees
                        Rectangle()
                            .fill(Color.nooraniTextSecondary.opacity(0.4))
                            .frame(width: 1, height: 8)
                            .padding(.top, 28)
                    }

                    Spacer()
                }
                .rotationEffect(.degrees(angle))
            }

            // Add intercardinal directions (NE, SE, SW, NW) at 45-degree intervals
            ForEach([45, 135, 225, 315], id: \.self) { angle in
                let directionIndex = (angle - 45) / 90
                let intercardinalDirections = ["NE", "SE", "SW", "NW"]

                VStack(spacing: 2) {
                    Text(intercardinalDirections[directionIndex])
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.nooraniTextSecondary)
                        .padding(.bottom, 6)

                    Rectangle()
                        .fill(Color.nooraniTextSecondary.opacity(0.6))
                        .frame(width: 2, height: 15)

                    Spacer()
                }
                .rotationEffect(.degrees(Double(angle)))
            }
        }
        .rotationEffect(.degrees(compassRotation))
        .animation(.easeInOut(duration: 0.5), value: compassRotation)
    }
}

// MARK: - 🎯 Ultra-Precise Qibla Arrow Component
struct QiblaArrowView: View {
    let qiblaDirection: Double?
    let currentHeading: Double?
    let isAligned: Bool
    let alignmentAccuracy: Double

    private var rotationAngle: Double {
        guard let qiblaDirection = qiblaDirection,
              let currentHeading = currentHeading else {
            return 0
        }

        // Calculate angle difference for arrow rotation
        return qiblaDirection - currentHeading
    }

    var body: some View {
        ZStack {
            // Arrow Body with gradient
            RoundedRectangle(cornerRadius: 4)
                .fill(
                    LinearGradient(
                        colors: isAligned ?
                        [.green, .green.opacity(0.7)] :
                        [Color.nooraniPrimary, Color.nooraniPrimary.opacity(0.7)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: isAligned ? 8 : 6, height: 100)
                .offset(y: -50)

            // Arrow Head with professional design
            ArrowHeadShape()
                .fill(isAligned ? .green : Color.nooraniPrimary)
                .frame(width: isAligned ? 32 : 26, height: isAligned ? 32 : 26)
                .offset(y: -105)
                .shadow(color: Color.nooraniShadow, radius: 3)
        }
        .rotationEffect(.degrees(rotationAngle))
        .opacity(qiblaDirection != nil && currentHeading != nil ? 1.0 : 0.4)
        .scaleEffect(isAligned ? 1.15 : 1.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: rotationAngle)
        .animation(.easeInOut(duration: 0.4), value: isAligned)
    }
}

// MARK: - 🔺 Arrow Head Shape
struct ArrowHeadShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height

        path.move(to: CGPoint(x: width * 0.5, y: 0))
        path.addLine(to: CGPoint(x: 0, y: height * 0.8))
        path.addLine(to: CGPoint(x: width * 0.5, y: height * 0.6))
        path.addLine(to: CGPoint(x: width, y: height * 0.8))
        path.closeSubpath()

        return path
    }
}

// MARK: - 🎯 Smart Alignment Status Component
struct AlignmentStatusView: View {
    let isAligned: Bool
    let accuracy: Double
    let angleDifference: Double?

    var body: some View {
        VStack(spacing: 15) {
            if isAligned {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title2)

                    Text("Aligned with Qibla")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
                .padding(.horizontal, 25)
                .padding(.vertical, 15)
                .background(Color.green.opacity(0.1))
                .cornerRadius(30)
                .overlay(
                    RoundedRectangle(cornerRadius: 30)
                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                )
            } else if let angleDiff = angleDifference {
                VStack(spacing: 10) {
                    Text("Rotate \(String(format: "%.1f", angleDiff))° to align")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(Color.nooraniTextSecondary)

                    // Smart Accuracy Progress Bar
                    ProgressView(value: accuracy / 100.0)
                        .progressViewStyle(LinearProgressViewStyle(tint: Color.nooraniPrimary))
                        .frame(width: 220, height: 8)
                        .scaleEffect(y: 2.0) // Make it thicker

                    Text("\(String(format: "%.0f", accuracy))% aligned")
                        .font(.caption)
                        .foregroundColor(Color.nooraniTextSecondary)
                }
                .padding(.horizontal, 25)
                .padding(.vertical, 15)
                .background(Color.nooraniCardBackground.opacity(0.9))
                .cornerRadius(20)
                .shadow(color: Color.nooraniShadow, radius: 5, x: 0, y: 2)
            }
        }
    }
}

// MARK: - 📋 Professional Info Card Component
struct InfoCard: View {
    let icon: String
    let title: String
    let value: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 18) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(Color.nooraniPrimary)
                .frame(width: 35)

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Color.nooraniTextPrimary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(Color.nooraniTextSecondary)
            }

            Spacer()

            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(Color.nooraniPrimary)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 18)
        .background(Color.nooraniCardBackground)
        .cornerRadius(15)
        .shadow(color: Color.nooraniShadow, radius: 8, x: 0, y: 4)
    }
}

#Preview {
    QiblaFinderView(locationManager: LocationManager())
}
