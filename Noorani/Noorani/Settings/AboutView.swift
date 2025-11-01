//
//  AboutView.swift
//  Noorani
//
//  Created by Amin Pourgol on 10/20/25.
//  Copyright © 2025 AP Bros. All rights reserved.
//

import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // Same gradient as home screen
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: Color(hex: "#fab555"), location: 0.0),
                    .init(color: Color(hex: "#feecd3"), location: 0.55),
                    .init(color: Color.white, location: 1.0)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(.all, edges: .vertical)
            
            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.white)
                            .font(.system(size: 18, weight: .medium))
                    }
                    
                    Text("About")
                        .font(.custom("Nunito-Bold", size: 24))
                        .foregroundColor(.black)
                        .padding(.leading, 10)
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        VStack(spacing: 15) {
                            Image("Logo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 80, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                .shadow(radius: 4, y: 2)
                            
                            Text("Noorani")
                                .font(.custom("Nunito-Regular", size: 28))
                                .fontWeight(.bold)
                                .foregroundColor(.black)
                            
                            Text("Prayer Times & Qibla")
                                .font(.custom("Nunito-Regular", size: 16))
                                .foregroundColor(.black.opacity(0.7))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 30)
                        
                        // Version Info
                        VStack(spacing: 1) {
                            AboutInfoRow(title: "Version", value: "1.0.0")
                            Divider().background(Color.gray.opacity(0.3))

                            
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 40)
                        
                        // Description
                        Text("About Noorani")
                            .font(.custom("Nunito-SemiBold", size: 18))
                            .foregroundColor(.black.opacity(0.8))
                            .padding(.horizontal, 20)
                            .padding(.top, 30)
                        
                        Text("Noorani provides accurate prayer times based on your location and preferred calculation method. The app supports diverse prayer time calculations, notifications, Islamic calendar, and a Qibla compass to help you find the direction of Mecca.")
                            .font(.custom("Nunito-Regular", size: 16))
                            .foregroundColor(.black.opacity(0.7))
                            .lineSpacing(4)
                            .padding(.horizontal, 20)
                            .padding(.top, 10)

                        // Contact & Support
                        VStack(spacing: 1) {
                            ActionRow(title: "Contact Support", systemImage: "envelope") {
                                contactSupport()
                            }
                            
                            Divider().background(Color.gray.opacity(0.3))
                            
                            ActionRow(title: "Privacy Policy", systemImage: "hand.raised") {
                                openPrivacyPolicy()
                            }
                            
                            Divider().background(Color.gray.opacity(0.3))
                            
                            ActionRow(title: "Terms of Service", systemImage: "doc.text") {
                                openTermsOfService()
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 30)
                    }
                }
                
                Spacer()
            }
        }
        .navigationBarHidden(true)
        .gesture(
            // Add swipe back gesture
            DragGesture()
                .onEnded { gesture in
                    if gesture.translation.width > 100 && abs(gesture.translation.height) < 50 {
                        dismiss()
                    }
                }
        )
    }
    

    
    private func contactSupport() {
        // Implementation for contacting support
        if let url = URL(string: "mailto:support@apbros.com") {
            UIApplication.shared.open(url)
        }
    }
    
    private func openPrivacyPolicy() {
        // Implementation for opening privacy policy
        if let url = URL(string: "https://your-website.com/privacy") {
            UIApplication.shared.open(url)
        }
    }
    
    private func openTermsOfService() {
        // Implementation for opening terms of service
        if let url = URL(string: "https://your-website.com/terms") {
            UIApplication.shared.open(url)
        }
    }
}

struct AboutInfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.custom("Nunito-Regular", size: 16))
                .foregroundColor(.black)
            
            Spacer()
            
            Text(value)
                .font(.custom("Nunito-Regular", size: 16))
                .foregroundColor(.black.opacity(0.7))
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 16)
    }
}

struct ActionRow: View {
    let title: String
    let systemImage: String
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: systemImage)
                    .foregroundColor(Color(hex: "#fab555"))
                    .font(.system(size: 16))
                    .frame(width: 20)
                
                Text(title)
                    .font(.custom("Nunito-Regular", size: 16))
                    .foregroundColor(.black)
                    .padding(.leading, 8)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(Color(hex: "#fab555"))
                    .font(.system(size: 16, weight: .medium))
            }
            .padding(.vertical, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    AboutView()
}
