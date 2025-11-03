//
//  PrivacyPolicyView.swift
//  Noorani
//
//  Created by Amin Pourgol on 11/3/25.
//  Copyright © 2025 AP Bros. All rights reserved.
//

import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
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
                    
                    Text("Privacy Policy")
                        .font(.custom("Nunito-Regular", size: 24))
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                        .padding(.leading, 10)
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Your Privacy Matters")
                            .font(.custom("Nunito-Regular", size: 20))
                            .fontWeight(.semibold)
                            .foregroundColor(.black)
                        
                        Text("Noorani is committed to protecting your privacy. Here's what you need to know:")
                            .font(.custom("Nunito-Regular", size: 15))
                            .foregroundColor(.black.opacity(0.7))
                        
                        VStack(alignment: .leading, spacing: 15) {
                            PrivacyBulletPoint(
                                icon: "location.fill",
                                title: "Location Data",
                                description: "We use your device's location to calculate accurate prayer times and Qibla direction. Location data is processed locally on your device."
                            )
                            
                            PrivacyBulletPoint(
                                icon: "bell.fill",
                                title: "Notifications",
                                description: "We send local notifications to remind you of prayer times. These are managed entirely on your device."
                            )
                            
                            PrivacyBulletPoint(
                                icon: "lock.fill",
                                title: "No Data Collection",
                                description: "We do not collect, store, or transmit your personal data to any servers. All information stays on your device."
                            )
                            
                            PrivacyBulletPoint(
                                icon: "person.fill.questionmark",
                                title: "Anonymous Usage",
                                description: "Prayer time calculations are fetched from a public API using only your location coordinates. No personally identifiable information is sent."
                            )
                            
                            PrivacyBulletPoint(
                                icon: "shield.fill",
                                title: "Data Security",
                                description: "All settings and preferences are stored securely on your device using iOS's secure storage mechanisms."
                            )
                            
                            PrivacyBulletPoint(
                                icon: "trash.fill",
                                title: "Data Deletion",
                                description: "You can delete all app data at any time by resetting the app settings or uninstalling the app."
                            )
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.08), radius: 20, x: 0, y: 8)
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 30)
                }
            }
        }
        .navigationBarHidden(true)
        .gesture(
            DragGesture()
                .onEnded { gesture in
                    if gesture.translation.width > 100 && abs(gesture.translation.height) < 50 {
                        dismiss()
                    }
                }
        )
    }
}

struct PrivacyBulletPoint: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(Color(hex: "#fab555"))
                .font(.system(size: 18))
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.custom("Nunito-Regular", size: 16))
                    .fontWeight(.semibold)
                    .foregroundColor(.black)
                
                Text(description)
                    .font(.custom("Nunito-Regular", size: 14))
                    .foregroundColor(.black.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

#Preview {
    PrivacyPolicyView()
}
