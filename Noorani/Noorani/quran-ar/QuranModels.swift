//
//  QuranModels.swift
//  Noorani
//  Copyright © 2025 AP Bros. All rights reserved.
 
 
//

import Foundation

// MARK: - 📖 Quran Data Models

/// Represents a complete Surah with both Arabic and translated text
struct Surah: Identifiable, Codable {
    let id: Int
    let city: String
    let name: SurahName
    let ayahs: Int
    let slug: String
    let translator: String?
    
    /// Combined Arabic and translated verses
    var verses: [Ayah] = []
    
    /// Computed properties for UI
    var cityDisplayName: String {
        city.capitalized
    }
    
    var revelationPlace: String {
        city.lowercased() == "makkah" ? "Meccan" : "Medinan"
    }

}

/// Represents the name of a Surah in different formats
struct SurahName: Codable {
    let translated: String
    let transliterated: String
    let codepoints: [Int]
    
    /// Convert codepoints to Arabic text
    var arabic: String {
        let characters = codepoints.compactMap { UnicodeScalar($0)?.description }
        return characters.joined()
    }
}

/// Represents a single verse (Ayah) with Arabic and translation
struct Ayah: Identifiable, Codable {
    let id: Int
    let arabic: String
    let translation: String
    
    init(number: Int, arabic: String, translation: String) {
        self.id = number
        self.arabic = arabic
        self.translation = translation
    }
}

// MARK: - 📊 Raw JSON Models (for parsing)

/// Raw structure from the JSON files
struct RawSurahData: Codable {
    let id: Int
    let city: String
    let name: SurahName
    let ayahs: Int
    let slug: String
    let translator: String?
}

/// Represents the complete JSON structure with metadata and verses
struct SurahJSON: Codable {
    let metadata: RawSurahData
    let verses: [[SurahJSONValue]]
    
    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        
        // First element is metadata
        metadata = try container.decode(RawSurahData.self)
        
        // Remaining elements are verse arrays
        var verseArrays: [[SurahJSONValue]] = []
        while !container.isAtEnd {
            let verseArray = try container.decode([SurahJSONValue].self)
            verseArrays.append(verseArray)
        }
        verses = verseArrays
    }
}

/// Handles both Int and String values in JSON arrays
enum SurahJSONValue: Codable {
    case int(Int)
    case string(String)
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intValue = try? container.decode(Int.self) {
            self = .int(intValue)
        } else if let stringValue = try? container.decode(String.self) {
            self = .string(stringValue)
        } else {
            throw DecodingError.typeMismatch(
                SurahJSONValue.self,
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Expected Int or String"
                )
            )
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .int(let intValue):
            try container.encode(intValue)
        case .string(let stringValue):
            try container.encode(stringValue)
        }
    }
    
    var intValue: Int? {
        if case .int(let value) = self { return value }
        return nil
    }
    
    var stringValue: String? {
        if case .string(let value) = self { return value }
        return nil
    }
}

// MARK: - 📱 UI Helper Extensions

extension Surah {
    /// Returns appropriate background gradient colors based on revelation place
    var gradientColors: [String] {
        switch city.lowercased() {
        case "makkah":
            return ["#fab555", "#feecd3", "#ffffff"] // Golden gradient for Meccan
        default:
            return ["#8ab4f8", "#dae8fc", "#ffffff"] // Blue gradient for Medinan
        }
    }
    
    /// Returns appropriate text color for the surah
    var textColor: String {
        city.lowercased() == "makkah" ? "#8b5a00" : "#1565c0"
    }
}
