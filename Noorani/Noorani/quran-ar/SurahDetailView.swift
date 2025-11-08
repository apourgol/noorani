//
//  SurahDetailView.swift
//  Noorani
//  Copyright © 2025 AP Bros. All rights reserved.
 
 
//

import SwiftUI

/// 📖 Beautiful Surah Reading View with Consistent Design
struct SurahDetailView: View {
    let surah: Surah
    @Environment(\.dismiss) private var dismiss
    @State private var selectedAyah: Ayah?
    @State private var arabicFontSize: CGFloat = 28
    @State private var englishFontSize: CGFloat = 16
    @State private var showingSettings = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                // 🎨 Consistent Noorani Background (same as other views)
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
                
                VStack(spacing: 0) {
                    // Fixed top controls that don't move with scroll
                    topControlsView
                    
                    // Settings panel
                    if showingSettings {
                        settingsPanel
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    
                    // Main scrollable content
                    ScrollView {
                        LazyVStack(spacing: 20) {
                            // 📜 Beautiful Enhanced Surah Header with Surah Number
                            BeautifulSurahHeaderView(surah: surah)
                                .padding(.top, 5)
                            
                            // 📖 Bismillah (for all surahs except At-Tawbah) - Using Uthman Taha
                            if surah.id != 9 {
                                BismillahView(arabicFontSize: arabicFontSize)
                                    .padding(.horizontal, 20)
                            }
                            
                            // 📄 Verses with Arabic numbering in same line
                            LazyVStack(spacing: 16) {
                                ForEach(surah.verses) { ayah in
                                    EnhancedAyahView(
                                        ayah: ayah,
                                        surah: surah,
                                        arabicFontSize: arabicFontSize,
                                        englishFontSize: englishFontSize
                                    ) {
                                        selectedAyah = ayah
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 40)
                        }
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("")
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .bold))
                        Text("Back")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.primary)
                }
            }
        }
    }
    
    // MARK: - Fixed Top Controls (consistent with your Dua project style)
    private var topControlsView: some View {
        HStack {
            Spacer()
            
            // Settings button with your Dua project style
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    showingSettings.toggle()
                }
            }) {
                Image(systemName: showingSettings ? "gearshape.fill" : "gearshape")
                    .foregroundColor(.gray)
                    .font(.system(size: 22))
                    .frame(width: 40, height: 40)
                    .background(colorScheme == .dark ? Color.gray.opacity(0.3) : Color.white.opacity(0.8))
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 1)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
    }
    
    // MARK: - Settings Panel (matching your Dua project style)
    private var settingsPanel: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Text Size")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                Spacer()
                Button("Reset") {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        arabicFontSize = 28
                        englishFontSize = 16
                    }
                }
                .font(.caption)
                .foregroundColor(Color.nooraniPrimary)
                .padding(.trailing, 8)
                Button(action: {
                    withAnimation(.spring()) {
                        showingSettings = false
                    }
                }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.gray)
                        .font(.caption)
                        .padding(5)
                        .background(Color(.systemGray5))
                        .clipShape(Circle())
                }
            }
            .padding(.bottom, 2)

            // Arabic font control
            FontSizeControl(
                label: "Arabic",
                fontSize: $arabicFontSize,
                minFontSize: 16,
                maxFontSize: 40,
                step: 2,
                gradient: nooraniGradient,
                valueColor: Color.nooraniPrimary
            )
            
            // English font control  
            FontSizeControl(
                label: "English",
                fontSize: $englishFontSize,
                minFontSize: 10,
                maxFontSize: 24,
                step: 1,
                gradient: secondaryGradient,
                valueColor: Color.nooraniTextSecondary
            )
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(colorScheme == .dark ? Color(.systemGray6).opacity(0.95) : Color.white.opacity(0.98))
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
        )
        .padding(.horizontal, 8)
        .padding(.top, 4)
    }
    
    // MARK: - Gradients matching Noorani colors
    private var nooraniGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [Color.nooraniPrimary, Color.nooraniPrimary.opacity(0.8)]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var secondaryGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [Color.nooraniTextSecondary, Color.nooraniTextSecondary.opacity(0.8)]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: - Font Size Control (from your Dua project)
    private struct FontSizeControl: View {
        let label: String
        @Binding var fontSize: CGFloat
        let minFontSize: CGFloat
        let maxFontSize: CGFloat
        let step: CGFloat
        let gradient: LinearGradient
        let valueColor: Color
        
        var body: some View {
            HStack(spacing: 8) {
                Text(label)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(gradient)
                            .shadow(color: Color.black.opacity(0.08), radius: 2, x: 0, y: 1)
                    )
                Spacer()
                HStack(spacing: 6) {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            if fontSize > minFontSize {
                                fontSize -= step
                            }
                        }
                    }) {
                        Image(systemName: "minus")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 22, height: 22)
                            .background(Circle().fill(gradient))
                            .shadow(color: Color.black.opacity(0.08), radius: 2, x: 0, y: 1)
                    }
                    .disabled(fontSize <= minFontSize)
                    Text("\(Int(fontSize))")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(valueColor)
                        .frame(width: 28, height: 20)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(valueColor.opacity(0.10))
                                .shadow(color: valueColor.opacity(0.08), radius: 1, x: 0, y: 1)
                        )
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            if fontSize < maxFontSize {
                                fontSize += step
                            }
                        }
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 22, height: 22)
                            .background(Circle().fill(gradient))
                            .shadow(color: Color.black.opacity(0.08), radius: 2, x: 0, y: 1)
                    }
                    .disabled(fontSize >= maxFontSize)
                }
            }
            .padding(.vertical, 1)
        }
    }
}

// MARK: - 🔢 Arabic Number Helper
extension Int {
    /// Converts Western Arabic numerals (1234567890) to Eastern Arabic numerals (١٢٣٤٥٦٧٨٩٠)
    var toArabicNumerals: String {
        let arabicNumerals = ["٠", "١", "٢", "٣", "٤", "٥", "٦", "٧", "٨", "٩"]
        return String(self).compactMap { character in
            if let digit = Int(String(character)) {
                return arabicNumerals[digit]
            }
            return String(character)
        }.joined()
    }
}

// MARK: - 📜 Beautiful Enhanced Surah Header with Surah Number (MORE CONDENSED)
struct BeautifulSurahHeaderView: View {
    let surah: Surah
    
    var body: some View {
        VStack(spacing: 10) {
            // Surah Number in beautiful circle (smaller)
            Text("\(surah.id)")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(Color.nooraniPrimary)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
                        )
                        .shadow(color: Color.nooraniPrimary.opacity(0.4), radius: 4, x: 0, y: 2)
                )
            
            // Arabic Surah Name using Uthman Taha (condensed)
            Text(surah.name.arabic)
                .font(FontLoader.getArabicFont(size: 32, useUthmaniTaha: true))
                .fontWeight(.bold)
                .foregroundColor(Color.nooraniTextPrimary)
                .environment(\.layoutDirection, .rightToLeft)
                .multilineTextAlignment(.center)
                .shadow(color: Color.nooraniPrimary.opacity(0.2), radius: 1, x: 0, y: 1)
            
            // Perfect layout: Left bounded, centered, right bounded
            HStack {
                // LEFT BOUNDED - Revelation place icon 
                VStack(spacing: 3) {
                    Image(surah.city.lowercased() == "makkah" ? "makkah" : "madinah")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                        .foregroundColor(Color.nooraniPrimary)
                }
                .frame(width: 60) // Fixed width for left side
                
                Spacer()
                
                // CENTERED - English Translation and Transliteration
                VStack(spacing: 3) {
                    Text(surah.name.translated)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(Color.nooraniTextPrimary)
                        .multilineTextAlignment(.center)
                    
                    Text(surah.name.transliterated)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(Color.nooraniTextSecondary)
                        .italic()
                        .multilineTextAlignment(.center)
                }
                
                Spacer()
                
                // RIGHT BOUNDED - Verse count
                VStack(spacing: 1) {
                    Text("\(surah.ayahs)")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(Color.nooraniPrimary)
                    
                    Text("verses")
                        .font(.caption2)
                        .foregroundColor(Color.nooraniTextSecondary)
                }
                .frame(width: 60) // Fixed width for right side
            }
            .padding(.horizontal, 12)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 15)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.4), lineWidth: 1)
                )
                .shadow(color: Color.nooraniShadow.opacity(0.1), radius: 6, x: 0, y: 3)
        )
        .padding(.horizontal, 20)
    }
}

// MARK: - 📜 Enhanced Surah Header Component (Improved Layout)
struct EnhancedSurahHeaderView: View {
    let surah: Surah
    
    var body: some View {
        VStack(spacing: 20) {
            // Arabic Surah Name - BIG at the top
            Text(surah.name.arabic)
                .font(FontLoader.getArabicFont(size: 36, useUthmaniTaha: true))
                .fontWeight(.bold)
                .foregroundColor(Color.nooraniTextPrimary)
                .environment(\.layoutDirection, .rightToLeft)
                .multilineTextAlignment(.center)
                .padding(.top, 10)
            
            // Row with icon, English name, and transliteration
            HStack(spacing: 15) {
                // Revelation place icon (bigger)
                Image(surah.city.lowercased() == "makkah" ? "makkah" : "madinah")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)
                    .foregroundColor(Color.nooraniPrimary)
                
                // English Translation
                Text(surah.name.translated)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.nooraniTextPrimary)
                
                // Transliteration
                Text("(\(surah.name.transliterated))")
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(Color.nooraniTextSecondary)
                    .italic()
            }
            .padding(.horizontal, 20)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
        )
        .padding(.horizontal, 20)
    }
}

// MARK: - 🌟 Bismillah Component (Using Uthman Taha Font)
struct BismillahView: View {
    let arabicFontSize: CGFloat
    private let bismillahText = "بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ"
    
    var body: some View {
        VStack(spacing: 15) {
            Text(bismillahText)
                .font(FontLoader.getArabicFont(size: arabicFontSize + 4, useUthmaniTaha: true))
                .fontWeight(.medium)
                .foregroundColor(Color.nooraniTextPrimary)
                .environment(\.layoutDirection, .rightToLeft)
                .multilineTextAlignment(.center)
                .lineSpacing(6)
            
            Text("In the name of Allah, the Most Gracious, the Most Merciful")
                .font(.subheadline)
                .italic()
                .foregroundColor(Color.nooraniTextSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 25)
        .padding(.vertical, 25)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.nooraniPrimary.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - 📄 Enhanced Ayah with Arabic numbering in same line (BEAUTIFUL DESIGN!)
struct EnhancedAyahView: View {
    let ayah: Ayah
    let surah: Surah
    let arabicFontSize: CGFloat
    let englishFontSize: CGFloat
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 18) {
                // Arabic Text with verse number in same line - PROPER RTL ORDER
                HStack(alignment: .top, spacing: 8) {
                    // Beautiful Arabic verse number at LEFT side - FANCY PARENTHESES ﴿﴾
                    Text("﴾\(ayah.id.toArabicNumerals)﴿")
                        .font(FontLoader.getArabicFont(size: arabicFontSize * 0.85, useUthmaniTaha: true))
                        .foregroundColor(Color.nooraniPrimary)
                        .environment(\.layoutDirection, .rightToLeft)

                    Spacer()

                    // Arabic text - RIGHT side (rightmost position)
                    Text(ayah.arabic)
                        .font(FontLoader.getArabicFont(size: arabicFontSize, useUthmaniTaha: true))
                        .fontWeight(.medium)
                        .foregroundColor(Color.nooraniTextPrimary)
                        .multilineTextAlignment(.trailing)
                        .lineSpacing(arabicFontSize * 0.3)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }

                // English Translation - LEFT ALIGNED
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(ayah.translation)
                            .font(.system(size: englishFontSize, weight: .regular))
                            .foregroundColor(Color.nooraniTextSecondary)
                            .multilineTextAlignment(.leading)
                            .lineSpacing(englishFontSize * 0.25)
                        
                        // Verse number in English (smaller and subtle)
                        Text("Verse \(ayah.id)")
                            .font(.system(size: englishFontSize * 0.7, weight: .medium))
                            .foregroundColor(Color.nooraniTextSecondary.opacity(0.6))
                    }
                    
                    Spacer()
                }
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.white.opacity(0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.white.opacity(0.4), lineWidth: 1)
                    )
                    .shadow(color: Color.nooraniShadow.opacity(0.08), radius: 6, x: 0, y: 3)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 📄 Original Ayah (Verse) Component (kept for compatibility)
struct AyahView: View {
    let ayah: Ayah
    let surah: Surah
    let arabicFontSize: CGFloat
    let englishFontSize: CGFloat
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 18) {
                // Arabic Text - RIGHT ALIGNED with verse number
                HStack {
                    Spacer()
                    VStack(alignment: .trailing, spacing: 8) {
                        Text(ayah.arabic)
                            .font(FontLoader.getArabicFont(size: arabicFontSize, useUthmaniTaha: true))
                            .fontWeight(.medium)
                            .foregroundColor(Color.nooraniTextPrimary)
                            .environment(\.layoutDirection, .rightToLeft)
                            .multilineTextAlignment(.trailing)
                            .lineSpacing(arabicFontSize * 0.3)
                        
                        // Verse number in Arabic style
                        Text("﴿\(ayah.id)﴾")
                            .font(FontLoader.getArabicFont(size: arabicFontSize * 0.8, useUthmaniTaha: true))
                            .foregroundColor(Color.nooraniPrimary)
                            .environment(\.layoutDirection, .rightToLeft)
                    }
                }
                
                // English Translation - LEFT ALIGNED
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(ayah.translation)
                            .font(.system(size: englishFontSize, weight: .regular))
                            .foregroundColor(Color.nooraniTextSecondary)
                            .multilineTextAlignment(.leading)
                            .lineSpacing(englishFontSize * 0.25)
                        
                        // Verse number in English
                        Text("Verse \(ayah.id)")
                            .font(.system(size: englishFontSize * 0.75, weight: .medium))
                            .foregroundColor(Color.nooraniTextSecondary.opacity(0.7))
                    }
                    
                    Spacer()
                }
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.25))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    // Create sample data for preview
    let sampleSurah = Surah(
        id: 78,
        city: "makkah",
        name: SurahName(
            translated: "The Tidings",
            transliterated: "An-Naba",
            codepoints: [1575, 1604, 1606, 1576, 1573]
        ),
        ayahs: 2,
        slug: "an-naba",
        translator: "Dr. Mustafa Khattab"
    )
    
    SurahDetailView(surah: sampleSurah)
}
