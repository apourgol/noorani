//
//  PrayerTimesFetcher.swift
//  Noorani
//
//  Created by Amin Pourgol on 10/4/25.
//  Copyright © 2025 AP Bros. All rights reserved.
//

import Foundation
import SwiftUI

// MARK: - Prayer Calculation Method Models
struct CalculationMethod: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let params: MethodParams?
    let location: MethodLocation?
}

struct MethodParams: Codable, Hashable {
    let Fajr: Double?
    let Isha: IshaParam?
    let Maghrib: MaghribParam?
    let Midnight: String?
    let shafaq: String?
    
    enum IshaParam: Codable, Hashable {
        case degrees(Double)
        case minutes(String)
        
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let degrees = try? container.decode(Double.self) {
                self = .degrees(degrees)
            } else if let minutes = try? container.decode(String.self) {
                self = .minutes(minutes)
            } else {
                throw DecodingError.typeMismatch(IshaParam.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Expected Double or String"))
            }
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            switch self {
            case .degrees(let degrees):
                try container.encode(degrees)
            case .minutes(let minutes):
                try container.encode(minutes)
            }
        }
        
        var displayValue: String {
            switch self {
            case .degrees(let degrees):
                return "\(degrees)°"
            case .minutes(let minutes):
                return minutes
            }
        }
    }
    
    enum MaghribParam: Codable, Hashable {
        case degrees(Double)
        case minutes(String)
        
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let degrees = try? container.decode(Double.self) {
                self = .degrees(degrees)
            } else if let minutes = try? container.decode(String.self) {
                self = .minutes(minutes)
            } else {
                throw DecodingError.typeMismatch(MaghribParam.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Expected Double or String"))
            }
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            switch self {
            case .degrees(let degrees):
                try container.encode(degrees)
            case .minutes(let minutes):
                try container.encode(minutes)
            }
        }
    }
}

struct MethodLocation: Codable, Hashable {
    let latitude: Double
    let longitude: Double
}

struct CalculationMethodsResponse: Codable {
    let code: Int
    let status: String
    let data: [String: CalculationMethod]
}

// MARK: - Prayer Times API Response Models
// Note: Prayer response models are defined in PrayerResponse.swift

class PrayerTimesFetcher: ObservableObject {
    @Published var timings: [String: String] = [:]
    @Published var readableDate: String = ""
    @Published var hijriDate: String = ""
    @Published var prayerTimes: [String: Date] = [:] // Today's prayer times only
    @Published var nextPrayerName: String = ""
    @Published var nextPrayerTime: Date?
    @Published var countdown: String = ""
    @Published var isLoading: Bool = false
    @Published var availableMethods: [CalculationMethod] = []
    @Published var selectedMethod: CalculationMethod?
    
    @AppStorage("currentLat") var currentLat: Double = 0.0
    @AppStorage("currentLng") var currentLng: Double = 0.0
    @AppStorage("lastFetchDate") private var lastFetchDate: String = ""
    @AppStorage("cachedTimingsData") private var cachedTimingsData: Data = Data()
    @AppStorage("selectedMethodId") private var selectedMethodId: Int = 7 // Default to TEHRAN for Shia
    @AppStorage("cachedMethodsData") private var cachedMethodsData: Data = Data()

    private var timer: Timer?
    
    init() {
        loadCachedMethods()
        if availableMethods.isEmpty {
            loadDefaultMethods()
        }
        setSelectedMethod()
    }
    
    // Cache formatters to avoid recreating them
    private let apiDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yyyy"
        return formatter
    }()
    
    private let isoDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        return formatter
    }()
    
    // MARK: - Method Management
    private func loadDefaultMethods() {
        // Predefined methods based on your API response
        let defaultMethodsJSON = """
        {
            "MWL": {"id": 3, "name": "Muslim World League", "params": {"Fajr": 18, "Isha": 17}, "location": {"latitude": 51.5194682, "longitude": -0.1360365}},
            "ISNA": {"id": 2, "name": "Islamic Society of North America (ISNA)", "params": {"Fajr": 15, "Isha": 15}, "location": {"latitude": 39.70421229999999, "longitude": -86.39943869999999}},
            "EGYPT": {"id": 5, "name": "Egyptian General Authority of Survey", "params": {"Fajr": 19.5, "Isha": 17.5}, "location": {"latitude": 30.0444196, "longitude": 31.2357116}},
            "MAKKAH": {"id": 4, "name": "Umm Al-Qura University, Makkah", "params": {"Fajr": 18.5, "Isha": "90 min"}, "location": {"latitude": 21.3890824, "longitude": 39.8579118}},
            "KARACHI": {"id": 1, "name": "University of Islamic Sciences, Karachi", "params": {"Fajr": 18, "Isha": 18}, "location": {"latitude": 24.8614622, "longitude": 67.0099388}},
            "TEHRAN": {"id": 7, "name": "Institute of Geophysics, University of Tehran", "params": {"Fajr": 17.7, "Isha": 14, "Maghrib": 4.5, "Midnight": "JAFARI"}, "location": {"latitude": 35.6891975, "longitude": 51.3889736}},
            "JAFARI": {"id": 0, "name": "Shia Ithna-Ashari, Leva Institute, Qum", "params": {"Fajr": 16, "Isha": 14, "Maghrib": 4, "Midnight": "JAFARI"}, "location": {"latitude": 34.6415764, "longitude": 50.8746035}},
            "GULF": {"id": 8, "name": "Gulf Region", "params": {"Fajr": 19.5, "Isha": "90 min"}, "location": {"latitude": 24.1323638, "longitude": 53.3199527}},
            "KUWAIT": {"id": 9, "name": "Kuwait", "params": {"Fajr": 18, "Isha": 17.5}, "location": {"latitude": 29.375859, "longitude": 47.9774052}},
            "QATAR": {"id": 10, "name": "Qatar", "params": {"Fajr": 18, "Isha": "90 min"}, "location": {"latitude": 25.2854473, "longitude": 51.5310398}},
            "SINGAPORE": {"id": 11, "name": "Majlis Ugama Islam Singapura, Singapore", "params": {"Fajr": 20, "Isha": 18}, "location": {"latitude": 1.352083, "longitude": 103.819836}},
            "FRANCE": {"id": 12, "name": "Union Organization Islamic de France", "params": {"Fajr": 12, "Isha": 12}, "location": {"latitude": 48.856614, "longitude": 2.3522219}},
            "TURKEY": {"id": 13, "name": "Diyanet İşleri Başkanlığı, Turkey (experimental)", "params": {"Fajr": 18, "Isha": 17}, "location": {"latitude": 39.9333635, "longitude": 32.8597419}},
            "RUSSIA": {"id": 14, "name": "Spiritual Administration of Muslims of Russia", "params": {"Fajr": 16, "Isha": 15}, "location": {"latitude": 54.73479099999999, "longitude": 55.9578555}},
            "MOONSIGHTING": {"id": 15, "name": "Moonsighting Committee Worldwide (Moonsighting.com)", "params": {"shafaq": "general"}},
            "DUBAI": {"id": 16, "name": "Dubai (experimental)", "params": {"Fajr": 18.2, "Isha": 18.2}, "location": {"latitude": 25.0762677, "longitude": 55.087404}},
            "JAKIM": {"id": 17, "name": "Jabatan Kemajuan Islam Malaysia (JAKIM)", "params": {"Fajr": 20, "Isha": 18}, "location": {"latitude": 3.139003, "longitude": 101.686855}},
            "TUNISIA": {"id": 18, "name": "Tunisia", "params": {"Fajr": 18, "Isha": 18}, "location": {"latitude": 36.8064948, "longitude": 10.1815316}},
            "ALGERIA": {"id": 19, "name": "Algeria", "params": {"Fajr": 18, "Isha": 17}, "location": {"latitude": 36.753768, "longitude": 3.0587561}},
            "KEMENAG": {"id": 20, "name": "Kementerian Agama Republik Indonesia", "params": {"Fajr": 20, "Isha": 18}, "location": {"latitude": -6.2087634, "longitude": 106.845599}},
            "MOROCCO": {"id": 21, "name": "Morocco", "params": {"Fajr": 19, "Isha": 17}, "location": {"latitude": 33.9715904, "longitude": -6.8498129}},
            "PORTUGAL": {"id": 22, "name": "Comunidade Islamica de Lisboa", "params": {"Fajr": 18, "Maghrib": "3 min", "Isha": "77 min"}, "location": {"latitude": 38.7222524, "longitude": -9.1393366}},
            "JORDAN": {"id": 23, "name": "Ministry of Awqaf, Islamic Affairs and Holy Places, Jordan", "params": {"Fajr": 18, "Maghrib": "5 min", "Isha": 18}, "location": {"latitude": 31.9461222, "longitude": 35.923844}}
        }
        """
        
        if let data = defaultMethodsJSON.data(using: .utf8) {
            do {
                let methodsDict = try JSONDecoder().decode([String: CalculationMethod].self, from: data)
                availableMethods = Array(methodsDict.values).sorted { $0.id < $1.id }
                cacheMethods()
            } catch {
                print("Error loading default methods: \(error)")
            }
        }
    }
    
    private func loadCachedMethods() {
        guard !cachedMethodsData.isEmpty else { return }
        do {
            availableMethods = try JSONDecoder().decode([CalculationMethod].self, from: cachedMethodsData)
        } catch {
            print("Error loading cached methods: \(error)")
        }
    }
    
    private func cacheMethods() {
        do {
            cachedMethodsData = try JSONEncoder().encode(availableMethods)
        } catch {
            print("Error caching methods: \(error)")
        }
    }
    
    private func setSelectedMethod() {
        selectedMethod = availableMethods.first { $0.id == selectedMethodId } ?? availableMethods.first
    }
    
    func selectMethod(_ method: CalculationMethod) {
        selectedMethod = method
        selectedMethodId = method.id
        
        // Clear cached data to force refresh with new method
        lastFetchDate = ""
        cachedTimingsData = Data()
        
        // Refetch prayer times if we have location
        if currentLat != 0.0 && currentLng != 0.0 {
            fetchPrayerTimes(latitude: currentLat, longitude: currentLng)
        }
    }
    
    // Helper method to get recommended methods based on sect
    func getRecommendedMethods(for sect: String = "shia") -> [CalculationMethod] {
        if sect.lowercased() == "shia" {
            // Recommended Shia methods
            return availableMethods.filter { method in
                [0, 7].contains(method.id) // JAFARI, TEHRAN
            }
        } else {
            // Recommended Sunni methods
            return availableMethods.filter { method in
                [1, 2, 3, 4, 5].contains(method.id) // KARACHI, ISNA, MWL, MAKKAH, EGYPT
            }
        }
    }
    
    // Check if we need to fetch new data
    private func shouldFetchNewData(for latitude: Double, longitude: Double) -> Bool {
        let today = apiDateFormatter.string(from: Date())
        let locationChanged = abs(currentLat - latitude) > 0.001 || abs(currentLng - longitude) > 0.001
        let methodChanged = selectedMethod?.id != selectedMethodId
        return lastFetchDate != today || locationChanged || methodChanged || prayerTimes.isEmpty
    }

    func updateNextPrayer() {
        let now = Date()
        
        // Get all upcoming prayer times for today, sorted by time
        let upcomingPrayers = prayerTimes
            .filter { $0.value > now }
            .sorted { $0.value < $1.value }

        if let next = upcomingPrayers.first {
            nextPrayerName = next.key
            nextPrayerTime = next.value
            startCountdown(to: next.value)
        } else {
            // No more prayers today, we'll need tomorrow's data
            nextPrayerName = "Fajr (Tomorrow)"
            nextPrayerTime = nil
            countdown = ""
            timer?.invalidate()
        }
    }

    private var allowedPrayerKeys: Set<String> {
        // TODO: Customize this based on sect. Maybe make it configurable in settings?
        return ["Fajr", "Sunrise", "Dhuhr", "Sunset", "Maghrib", "Midnight"] // Shia
        // return ["Fajr", "Dhuhr", "Asr", "Maghrib", "Isha"] // Sunni
    }

    private func startCountdown(to date: Date) {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            let interval = date.timeIntervalSince(Date())
            if interval <= 0 {
                self?.countdown = "Now"
                self?.timer?.invalidate()
            } else {
                self?.countdown = self?.format(interval) ?? ""
            }
        }
    }

    private func format(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    func fetchPrayerTimes(latitude: Double, longitude: Double) {
        // Check if we need to fetch new data
        if !shouldFetchNewData(for: latitude, longitude: longitude) {
            print("Using cached prayer times")
            updateNextPrayer()
            return
        }
        
        guard let method = selectedMethod else {
            print("No calculation method selected")
            return
        }
        
        isLoading = true
        
        // Use the selected calculation method
        let todayString = apiDateFormatter.string(from: Date())
        let urlString = "https://api.aladhan.com/v1/timings/\(todayString)?latitude=\(latitude)&longitude=\(longitude)&method=\(method.id)&iso8601=true&midnightMode=1"
        
        guard let url = URL(string: urlString) else { 
            DispatchQueue.main.async { self.isLoading = false }
            return 
        }

        print("Fetching prayer times for: \(todayString) using method: \(method.name) (ID: \(method.id))")

        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let self = self else { return }
            
            defer {
                DispatchQueue.main.async { self.isLoading = false }
            }
            
            guard let data = data, error == nil else { 
                print("Network error: \(error?.localizedDescription ?? "Unknown error")")
                return 
            }

            do {
                let response = try JSONDecoder().decode(PrayerResponse.self, from: data)
                
                // Process data on background thread
                let processedData = self.processSingleDayResponse(response)
                
                // Update UI on main thread
                DispatchQueue.main.async {
                    self.timings = processedData.timings
                    self.readableDate = processedData.readableDate
                    self.hijriDate = processedData.hijriDate
                    self.prayerTimes = processedData.prayerTimes
                    
                    // Update cached values
                    self.lastFetchDate = self.apiDateFormatter.string(from: Date())
                    self.currentLat = latitude
                    self.currentLng = longitude
                    
                    self.updateNextPrayer()
                }
            } catch {
                print("Decoding error: \(error)")
            }
        }.resume()
    }
    
    private func processSingleDayResponse(_ response: PrayerResponse) -> (timings: [String: String], readableDate: String, hijriDate: String, prayerTimes: [String: Date]) {
        let now = Date()
        var resultPrayerTimes: [String: Date] = [:]
        
        // Convert timings to Date objects
        for (name, timeString) in response.data.timings {
            guard allowedPrayerKeys.contains(name) else { continue }
            if let prayerDate = isoDateFormatter.date(from: timeString) {
                // Only include future prayer times
                if prayerDate > now {
                    resultPrayerTimes[name] = prayerDate
                }
            } else {
                print("Failed to parse \(name): \(timeString)")
            }
        }
        
        return (
            timings: response.data.timings,
            readableDate: response.data.date.readable,
            hijriDate: response.data.date.hijri.date,
            prayerTimes: resultPrayerTimes
        )
    }
}

#Preview {
    ContentView()
}