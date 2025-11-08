//
//  Font+Arabic.swift
//  Noorani
//  Copyright © 2025 AP Bros. All rights reserved.

import SwiftUI

extension Font {
    // MARK: - 📖 Arabic Font Options
    
    /// Arabic font using Uthman Taha (if available) or system fallback
    static func arabicUthmaniTaha(size: CGFloat) -> Font {
        return Font.custom("KFGQPC Uthman Taha Naskh Bold", size: size)
    }
    
    /// Arabic font using system font with proper Arabic support
    static func arabicSystem(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        return Font.system(size: size, weight: weight, design: .default)
    }
    
    // MARK: - 🎨 Predefined Arabic Font Sizes
    
    /// Large Arabic title (for Surah names)
    static var arabicTitle: Font {
        arabicUthmaniTaha(size: 32)
    }
    
    /// Medium Arabic text (for verses)
    static var arabicVerse: Font {
        arabicUthmaniTaha(size: 24)
    }
    
    /// Small Arabic text (for Bismillah)
    static var arabicBismillah: Font {
        arabicUthmaniTaha(size: 20)
    }
    
    /// System Arabic title (fallback option)
    static var arabicTitleSystem: Font {
        arabicSystem(size: 32, weight: .bold)
    }
    
    /// System Arabic verse (fallback option)  
    static var arabicVerseSystem: Font {
        arabicSystem(size: 24, weight: .medium)
    }
    
    /// System Arabic Bismillah (fallback option)
    static var arabicBismillahSystem: Font {
        arabicSystem(size: 20, weight: .medium)
    }
}

// MARK: - 🔧 Font Loading Helper
struct FontLoader {
    /// Check if Uthman Taha font is available
    static var isUthmaniTahaAvailable: Bool {
        return UIFont(name: "KFGQPC Uthman Taha Naskh Bold", size: 16) != nil
    }
    
    /// Get appropriate Arabic font based on availability
    static func getArabicFont(size: CGFloat, useUthmaniTaha: Bool = true) -> Font {
        if useUthmaniTaha && isUthmaniTahaAvailable {
            return Font.arabicUthmaniTaha(size: size)
        } else {
            return Font.arabicSystem(size: size, weight: .medium)
        }
    }
}
