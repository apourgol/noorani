//
//  QuranView.swift
//  Noorani
//  Copyright © 2025 AP Bros. All rights reserved.
 
 
//

import SwiftUI

/// 📖 Beautiful Quran View - Juz 30 (Surahs 78-114)
struct QuranView: View {
    @StateObject private var quranManager = QuranManager()
    @State private var searchText = ""
    
    var filteredSurahs: [Surah] {
        if searchText.isEmpty {
            return quranManager.surahs
        } else {
            return quranManager.surahs.filter { surah in
                surah.name.translated.localizedCaseInsensitiveContains(searchText) ||
                surah.name.transliterated.localizedCaseInsensitiveContains(searchText) ||
                surah.name.arabic.contains(searchText) ||
                "\(surah.id)".contains(searchText)
            }
        }
    }

    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                // 🎨 Beautiful Noorani Background
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color.nooraniPrimary, location: 0.0),      // Golden
                        .init(color: Color.nooraniSecondary, location: 0.4),    // Light cream
                        .init(color: Color.nooraniBackground, location: 1.0)    // White
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea(.all, edges: .vertical)
                
                ScrollView {
                    LazyVStack(spacing: 20) {
                        // 📖 Header Section
                        QuranHeaderView()
                            .padding(.top, 20)
                        
                        // 🔍 Search Bar
                        SearchBar(text: $searchText)
                            .padding(.horizontal, 20)
                        
                        if quranManager.isLoading {
                            // ⏳ Loading State
                            VStack(spacing: 20) {
                                ProgressView()
                                    .scaleEffect(1.5)
                                    .tint(Color.nooraniPrimary)
                                
                                Text("Loading All Surahs...")
                                    .font(.headline)
                                    .foregroundColor(Color.nooraniTextSecondary)
                            }
                            .padding(.top, 60)
                            
                        } else if let errorMessage = quranManager.errorMessage {
                            // ❌ Error State
                            ErrorView(message: errorMessage) {
                                Task {
                                    await quranManager.loadAllSurahs()
                                }
                            }
                            .padding(.horizontal, 20)
                            
                        } else if quranManager.surahs.isEmpty {
                            // 📋 Empty State (no surahs loaded)
                            VStack(spacing: 20) {
                                Image(systemName: "book.closed")
                                    .font(.system(size: 60))
                                    .foregroundColor(Color.nooraniTextSecondary)
                                
                                Text("No Quran Data Found")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color.nooraniTextPrimary)
                                
                                Text("ERROR: Quran data is either not available or not loaded yet. Please try again later.")
                                    .font(.body)
                                    .foregroundColor(Color.nooraniTextSecondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 20)
                                
                                Button("Try Again") {
                                    Task {
                                        await quranManager.loadAllSurahs()
                                    }
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 30)
                                .padding(.vertical, 12)
                                .background(Color.nooraniPrimary)
                                .cornerRadius(25)
                            }
                            .padding(.top, 60)
                            
                        } else {
                            // 📋 Surah List
                            LazyVStack(spacing: 12) {
                                ForEach(filteredSurahs) { surah in
                                    NavigationLink(destination: SurahDetailView(surah: surah)) {
                                        SurahCard(surah: surah)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 40)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
}

// MARK: - 📖 Header Component
struct QuranHeaderView: View {
    var body: some View {
        VStack(spacing: 15) {
            // 📖 Custom Book Asset (condensed size)
            Image("book")
                .resizable()
                .scaledToFit()
                .frame(width: 42, height: 42)
                .foregroundColor(Color.nooraniPrimary)
                .shadow(color: Color.nooraniPrimary.opacity(0.3), radius: 6, x: 0, y: 0)
            
            // Title
            Text("Holy Quran")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(Color.nooraniTextPrimary)
            
            // Subtitle
            Text("Juz 1-30 • Surahs 1-114")
                .font(.subheadline)
                .foregroundColor(Color.nooraniTextSecondary)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(Color.nooraniCardBackground.opacity(0.7))
                .cornerRadius(15)
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - 🔍 Search Bar Component  
struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Color.nooraniTextSecondary)
                .font(.system(size: 16))
            
            TextField("Search surahs...", text: $text)
                .font(.system(size: 16))
                .foregroundColor(Color.nooraniTextPrimary)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Color.nooraniTextSecondary)
                        .font(.system(size: 16))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.nooraniCardBackground)
        .cornerRadius(20)
        .shadow(color: Color.nooraniShadow, radius: 4, x: 0, y: 2)
    }
}

// MARK: - 📄 Surah Card Component
struct SurahCard: View {
    let surah: Surah
    
    var body: some View {
        HStack(spacing: 16) {
            // Surah Number Circle
            ZStack {
                Circle()
                    .fill(Color.nooraniPrimary.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Text("\(surah.id)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(Color.nooraniPrimary)
            }
            
            // Surah Info
            VStack(alignment: .leading, spacing: 6) {
                // Arabic Name (from codepoints)
                Text(surah.name.arabic)
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(Color.nooraniTextPrimary)
                    .environment(\.layoutDirection, .rightToLeft)
                
                // English Name
                Text(surah.name.translated)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Color.nooraniTextSecondary)
                
                // Transliterated Name
                Text(surah.name.transliterated)
                    .font(.caption)
                    .foregroundColor(Color.nooraniTextSecondary)
            }
            
            Spacer()
            
            // Metadata
            VStack(alignment: .trailing, spacing: 4) {
                // Revelation Place with custom icon
                HStack(spacing: 4) {
                    Image(surah.city.lowercased() == "makkah" ? "makkah" : "madinah")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                    Text(surah.revelationPlace)
                        .font(.caption)
                }
                .foregroundColor(Color.nooraniPrimary)
                
                // Verse Count
                Text("\(surah.ayahs) verses")
                    .font(.caption2)
                    .foregroundColor(Color.nooraniTextSecondary)
                
                // Arrow
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(Color.nooraniTextSecondary)
                    .padding(.top, 4)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.nooraniCardBackground)
        .cornerRadius(16)
        .shadow(color: Color.nooraniShadow, radius: 8, x: 0, y: 4)
    }
}

// MARK: - ❌ Error View Component
struct ErrorView: View {
    let message: String
    let retryAction: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            Text("Oops!")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Color.nooraniTextPrimary)
            
            Text(message)
                .font(.body)
                .foregroundColor(Color.nooraniTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            
            Button(action: retryAction) {
                Text("Try Again")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 12)
                    .background(Color.nooraniPrimary)
                    .cornerRadius(25)
            }
        }
        .padding(30)
        .background(Color.nooraniCardBackground)
        .cornerRadius(20)
        .shadow(color: Color.nooraniShadow, radius: 10, x: 0, y: 5)
    }
}

#Preview {
    QuranView()
}
