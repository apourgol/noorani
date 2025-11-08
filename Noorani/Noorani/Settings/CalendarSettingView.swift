//
//  CalendarSettingView.swift
//  Noorani
//  Copyright © 2025 AP Bros. All rights reserved.
 
  
//

import SwiftUI

struct CalendarSettingView: View {
    @AppStorage("calendarType") private var calendarType: String = "both" // "hijri", "gregorian", "both"
    @AppStorage("hijriOffset") private var hijriOffset: Int = 0 // Offset for Hijri date adjustment
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
                    
                    Text("Calendar Setting")
                        .font(.custom("Nunito-Regular", size: 24))
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                        .padding(.leading, 10)
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        // Calendar Type Section
                        Text("Calendar Display")
                            .font(.custom("Nunito-SemiBold", size: 18))
                            .foregroundColor(.black.opacity(0.8))
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                        
                        VStack(spacing: 1) {
                            CalendarTypeRow(
                                title: "Both (Hijri & Gregorian)",
                                type: "both",
                                currentType: calendarType
                            ) {
                                calendarType = "both"
                            }
                            
                            Divider()
                                .background(Color.gray.opacity(0.3))
                            
                            CalendarTypeRow(
                                title: "Hijri Only",
                                type: "hijri",
                                currentType: calendarType
                            ) {
                                calendarType = "hijri"
                            }
                            
                            Divider()
                                .background(Color.gray.opacity(0.3))
                            
                            CalendarTypeRow(
                                title: "Gregorian Only",
                                type: "gregorian",
                                currentType: calendarType
                            ) {
                                calendarType = "gregorian"
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                        
                        // Hijri Date Adjustment Section
                        Text("Hijri Date Adjustment")
                            .font(.custom("Nunito-SemiBold", size: 18))
                            .foregroundColor(.black.opacity(0.8))
                            .padding(.horizontal, 20)
                            .padding(.top, 30)
                        
                        HStack {
                            Text("Offset (days)")
                                .font(.custom("Nunito-Regular", size: 16))
                                .foregroundColor(.black)
                            
                            Spacer()
                            
                            HStack(spacing: 15) {
                                Button(action: {
                                    if hijriOffset > -10 {
                                        hijriOffset -= 1
                                    }
                                }) {
                                    Image(systemName: "minus.circle")
                                        .foregroundColor(Color(hex: "#fab555"))
                                        .font(.system(size: 24))
                                }
                                
                                Text("\(hijriOffset >= 0 ? "+" : "")\(hijriOffset)")
                                    .font(.custom("Nunito-SemiBold", size: 16))
                                    .foregroundColor(.black)
                                    .frame(minWidth: 40)
                                
                                Button(action: {
                                    if hijriOffset < 10 {
                                        hijriOffset += 1
                                    }
                                }) {
                                    Image(systemName: "plus.circle")
                                        .foregroundColor(Color(hex: "#fab555"))
                                        .font(.system(size: 24))
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                        
                        Text("Adjust the Hijri date if it doesn't match your local moon sighting")
                            .font(.custom("Nunito-Light", size: 14))
                            .foregroundColor(.black.opacity(0.6))
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
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
}

struct CalendarTypeRow: View {
    let title: String
    let type: String
    let currentType: String
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Text(title)
                    .font(.custom("Nunito-Regular", size: 16))
                    .foregroundColor(.black)
                
                Spacer()
                
                if currentType == type {
                    Image(systemName: "checkmark")
                        .foregroundColor(Color(hex: "#fab555"))
                        .font(.system(size: 16, weight: .medium))
                }
            }
            .padding(.vertical, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    CalendarSettingView()
}
