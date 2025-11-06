//
//  QuranManager.swift
//  Noorani
//  Copyright © 2025 AP Bros. All rights reserved.
 
 
//

import Foundation
import SwiftUI

/// 📖 Manages Quran data loading and caching
@MainActor
class QuranManager: ObservableObject {
    @Published var surahs: [Surah] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let surahRange = 1...114 // All surahs
    
    // MARK: - Initialization
    init() {
        Task {
            await loadAllSurahs()
        }
    }
    
    // MARK: - Test Data (for development)
    private func createTestData() {
        // Create sample surahs for testing
        let testSurah1 = Surah(
            id: 1,
            city: "makkah",
            name: SurahName(
                translated: "The Opening",
                transliterated: "Al-Fatihah",
                codepoints: [1575, 1604, 1601, 1575, 1578, 1581, 1577]
            ),
            ayahs: 7,
            slug: "al-fatihah",
            translator: "Dr. Mustafa Khattab"
        )
        
        let testSurah2 = Surah(
            id: 2,
            city: "madinah", 
            name: SurahName(
                translated: "The Cow",
                transliterated: "Al-Baqarah",
                codepoints: [1575, 1604, 1576, 1602, 1585, 1577]
            ),
            ayahs: 286,
            slug: "al-baqarah",
            translator: "Dr. Mustafa Khattab"
        )
        
        // Add sample verses
        var surah1 = testSurah1
        surah1.verses = [
            Ayah(number: 1, arabic: "بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ", translation: "In the name of Allah, the Entirely Merciful, the Especially Merciful."),
            Ayah(number: 2, arabic: "الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ", translation: "All praise is due to Allah, Lord of the worlds -"),
            Ayah(number: 3, arabic: "الرَّحْمَٰنِ الرَّحِيمِ", translation: "The Entirely Merciful, the Especially Merciful,")
        ]
        
        var surah2 = testSurah2
        surah2.verses = [
            Ayah(number: 1, arabic: "الم", translation: "Alif, Lam, Meem."),
            Ayah(number: 2, arabic: "ذَٰلِكَ الْكِتَابُ لَا رَيْبَ ۛ فِيهِ ۛ هُدًى لِّلْمُتَّقِينَ", translation: "This is the Book about which there is no doubt, a guidance for those conscious of Allah -"),
            Ayah(number: 3, arabic: "الَّذِينَ يُؤْمِنُونَ بِالْغَيْبِ وَيُقِيمُونَ الصَّلَاةَ وَمِمَّا رَزَقْنَاهُمْ يُنفِقُونَ", translation: "Who believe in the unseen, establish prayer, and spend out of what We have provided for them,")
        ]
        
        surahs = [surah1, surah2]
    }
    
    // MARK: - Public Methods
    
    /// Loads all Surahs from JSON files (78-114)
    func loadAllSurahs() async {
        isLoading = true
        errorMessage = nil
        

            var loadedSurahs: [Surah] = []
            
            // Debug: Let's check what files are actually available
            print("🔍 Checking available JSON files...")
            
            for surahNumber in surahRange {
                if let surah = await loadSurah(number: surahNumber) {
                    loadedSurahs.append(surah)
                    print("✅ Loaded Surah \(surahNumber): \(surah.name.translated)")
                } else {
                    print("❌ Failed to load Surah \(surahNumber)")
                }
            }
            
            // Sort by ID to ensure correct order
            surahs = loadedSurahs.sorted { $0.id < $1.id }
            print("📖 Successfully loaded \(surahs.count) Surahs out of \(surahRange.count) total")
            
            if surahs.isEmpty {
                print("⚠️ No JSON files found, using test data")
                print("🔍 Expected file patterns:")
                print("   - Method 1: 1-ar.json, 1-en.json, etc.")
                print("   - Method 2: quran-ar/1.json, quran/1.json, etc.")  
                print("   - Method 3: 1.json, 2.json, etc.")
                createTestData() // Fallback to test data
            } else {
                print("✅ Loaded Surahs: \(surahs.map { "\($0.id): \($0.name.transliterated)" }.joined(separator: ", "))")
            }
            
        
        
        isLoading = false
    }
    
    /// Gets a specific Surah by ID
    func getSurah(id: Int) -> Surah? {
        return surahs.first { $0.id == id }
    }
    
    /// Gets Meccan Surahs
    var meccanSurahs: [Surah] {
        surahs.filter { $0.city.lowercased() == "makkah" }
    }
    
    /// Gets Medinan Surahs
    var medinanSurahs: [Surah] {
        surahs.filter { $0.city.lowercased() == "madinah" }
    }
    
    // MARK: - Private Methods
    
    /// Loads a single Surah and combines Arabic + Translation
    private func loadSurah(number: Int) async -> Surah? {
        // Method 1: Try renamed files (78-ar.json, 78-en.json)
        do {
            let arabicData = try await loadJSONFile(name: "\(number)-ar", folder: nil)
            let arabicSurah = try parseJSONData(arabicData)
            
            let translationData = try await loadJSONFile(name: "\(number)-en", folder: nil)
            let translationSurah = try parseJSONData(translationData)
            
            return combineSurahData(arabic: arabicSurah, translation: translationSurah)
            
        } catch let method1Error {
            // Method 2: Try folder structure (quran-ar/78.json, quran/78.json)
            do {
                let arabicData = try await loadJSONFile(name: "\(number)", folder: "quran-ar")
                let arabicSurah = try parseJSONData(arabicData)
                
                let translationData = try await loadJSONFile(name: "\(number)", folder: "quran")
                let translationSurah = try parseJSONData(translationData)
                
                return combineSurahData(arabic: arabicSurah, translation: translationSurah)
                
            } catch let method2Error {
                // Method 3: Try single file approach (assuming you have translation file only)
                do {
                    let data = try await loadJSONFile(name: "\(number)", folder: nil)
                    let surah = try parseJSONData(data)
                    
                    // Create a surah from single file (assume it's the translation file)
                    return createSurahFromSingleFile(surah, surahNumber: number)
                    
                } catch let method3Error {
                    print("❌ All loading methods failed for Surah \(number):")
                    print("   Method 1 (renamed files): \(method1Error.localizedDescription)")
                    print("   Method 2 (folder structure): \(method2Error.localizedDescription)")
                    print("   Method 3 (single file): \(method3Error.localizedDescription)")
                    return nil
                }
            }
        }
    }
    
    /// Creates a Surah from a single JSON file (translation only)
    private func createSurahFromSingleFile(_ surahData: SurahJSON, surahNumber: Int) -> Surah {
        var surah = Surah(
            id: surahData.metadata.id,
            city: surahData.metadata.city,
            name: surahData.metadata.name,
            ayahs: surahData.metadata.ayahs,
            slug: surahData.metadata.slug,
            translator: surahData.metadata.translator
        )
        
        // Convert verses (assume they're translation only for now)
        var verses: [Ayah] = []
        
        for verse in surahData.verses {
            if let verseNumber = verse.first?.intValue,
               let text = verse.last?.stringValue {
                
                let ayah = Ayah(
                    number: verseNumber,
                    arabic: "القرآن الكريم", // Placeholder Arabic
                    translation: text
                )
                verses.append(ayah)
            }
        }
        
        surah.verses = verses
        return surah
    }
    
    /// Loads JSON file from bundle
    private func loadJSONFile(name: String, folder: String?) async throws -> Data {
        let url: URL?
        
        if let folder = folder {
            url = Bundle.main.url(forResource: name, withExtension: "json", subdirectory: folder)
        } else {
            url = Bundle.main.url(forResource: name, withExtension: "json")
        }
        
        guard let fileURL = url else {
            let location = folder != nil ? "in \(folder!) folder" : "in main bundle"
            throw QuranError.fileNotFound("Could not find \(name).json \(location)")
        }
        
        return try Data(contentsOf: fileURL)
    }
    
    /// Parses JSON data into SurahJSON structure
    private func parseJSONData(_ data: Data) throws -> SurahJSON {
        let decoder = JSONDecoder()
        return try decoder.decode(SurahJSON.self, from: data)
    }
    
    /// Combines Arabic and Translation data into a single Surah
    private func combineSurahData(arabic: SurahJSON, translation: SurahJSON) -> Surah {
        var surah = Surah(
            id: arabic.metadata.id,
            city: arabic.metadata.city,
            name: arabic.metadata.name,
            ayahs: arabic.metadata.ayahs,
            slug: arabic.metadata.slug,
            translator: translation.metadata.translator
        )
        
        // Combine verses
        var combinedVerses: [Ayah] = []
        
        // Process each verse
        for (index, arabicVerse) in arabic.verses.enumerated() {
            guard index < translation.verses.count else { break }
            
            let translationVerse = translation.verses[index]
            
            // Extract verse number and text
            if let verseNumber = arabicVerse.first?.intValue,
               let arabicText = arabicVerse.last?.stringValue,
               let translatedText = translationVerse.last?.stringValue {
                
                let ayah = Ayah(
                    number: verseNumber,
                    arabic: arabicText,
                    translation: translatedText
                )
                combinedVerses.append(ayah)
            }
        }
        
        surah.verses = combinedVerses
        return surah
    }
}

// MARK: - Error Types
enum QuranError: Error, LocalizedError {
    case fileNotFound(String)
    case parsingError(String)
    case networkError(String)
    
    var errorDescription: String? {
        switch self {
        case .fileNotFound(let message):
            return "File not found: \(message)"
        case .parsingError(let message):
            return "Parsing error: \(message)"
        case .networkError(let message):
            return "Network error: \(message)"
        }
    }
}
