//
//  TermsOfServiceView.swift
//  Noorani
//
//  Created by Amin Pourgol on 11/3/25.
//  Copyright © 2025 AP Bros. All rights reserved.
//

import SwiftUI

struct TermsOfServiceView: View {
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
                    
                    Text("Terms of Service")
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
                        Text("Terms & Conditions")
                            .font(.custom("Nunito-Regular", size: 20))
                            .fontWeight(.semibold)
                            .foregroundColor(.black)
                        
                        Text("By using Noorani, you agree to the following terms:")
                            .font(.custom("Nunito-Regular", size: 15))
                            .foregroundColor(.black.opacity(0.7))
                        
                        VStack(alignment: .leading, spacing: 15) {
                            TermsBulletPoint(
                                number: "1",
                                title: "Service Provided",
                                description: "Noorani provides Islamic prayer times and Qibla direction based on your location. Prayer times are calculated using established Islamic calculation methods."
                            )
                            
                            TermsBulletPoint(
                                number: "2",
                                title: "Location Permission",
                                description: "To provide accurate prayer times and Qibla direction, the app requires access to your device's location. This data is only used for calculations and is not stored or shared."
                            )
                            
                            TermsBulletPoint(
                                number: "3",
                                title: "Notification Permission",
                                description: "The app can send notifications to remind you of prayer times. You can enable or disable notifications at any time in the app settings."
                            )
                            
                            TermsBulletPoint(
                                number: "4",
                                title: "Data Usage",
                                description: "We collect basic geolocation data to calculate prayer times and Qibla direction. All data processing is anonymous, and nothing is stored on external servers."
                            )
                            
                            TermsBulletPoint(
                                number: "5",
                                title: "Accuracy Disclaimer",
                                description: "While we strive for accuracy, prayer times may vary slightly based on calculation methods and local customs. Please verify with your local mosque or Islamic center when needed."
                            )
                            
                            TermsBulletPoint(
                                number: "6",
                                title: "Free to Use",
                                description: "Noorani is provided free of charge. We do not sell your data or display advertisements within the app."
                            )
                            
                            TermsBulletPoint(
                                number: "7",
                                title: "Updates & Changes",
                                description: "We may update these terms from time to time. Continued use of the app constitutes acceptance of any changes."
                            )
                            
                            TermsBulletPoint(
                                number: "8",
                                title: "Contact",
                                description: "If you have any questions or concerns about these terms, please contact us through the About section of the app."
                            )
                        }
                        
                        Text("Last Updated: November 2025")
                            .font(.custom("Nunito-Regular", size: 13))
                            .foregroundColor(.black.opacity(0.5))
                            .padding(.top, 10)
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

struct TermsBulletPoint: View {
    let number: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(hex: "#fab555").opacity(0.2))
                    .frame(width: 28, height: 28)
                
                Text(number)
                    .font(.custom("Nunito-Regular", size: 14))
                    .fontWeight(.semibold)
                    .foregroundColor(Color(hex: "#fab555"))
            }
            
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
    TermsOfServiceView()
}
