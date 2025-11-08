//
//  AboutView.swift
//  Noorani
//  Copyright © 2025 AP Bros. All rights reserved.
//

import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var navigationPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                // Same gradient as home screen
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: .nooraniPrimary, location: 0.0),
                        .init(color: .nooraniSecondary, location: 0.55),
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
                            .font(.custom("Nunito-Regular", size: 24))
                            .foregroundColor(.nooraniTextPrimary)
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
                                    .foregroundColor(.nooraniTextPrimary)

                                Text("Prayer Times. Holy Quran. Qibla Direction.")
                                    .font(.custom("Nunito-Regular", size: 16))
                                    .foregroundColor(.nooraniTextSecondary)
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
                                .foregroundColor(.nooraniTextSecondary)
                                .padding(.horizontal, 20)
                                .padding(.top, 30)

                            Text("Noorani provides accurate prayer times based on your location and preferred calculation method. The app supports various prayer time calculations, the Holy Quran, and a Qibla compass to help you find the direction of Mecca.")
                                .font(.custom("Nunito-Regular", size: 16))
                                .foregroundColor(.black.opacity(0.7))
                                .lineSpacing(4)
                                .padding(.horizontal, 20)
                                .padding(.top, 10)

                            // Developer Section
                            VStack(alignment: .leading, spacing: 15) {
                                Text("Developed by")
                                    .font(.custom("Nunito-SemiBold", size: 18))
                                    .foregroundColor(.nooraniTextSecondary)
                                    .padding(.horizontal, 20)

                                VStack(spacing: 12) {
                                    // Developer Card
                                    VStack(spacing: 15) {
                                        HStack {
                                            Image(systemName: "laptopcomputer")
                                                .font(.system(size: 24))
                                                .foregroundColor(.nooraniPrimary)
                                            
                                            Text("Amir Pourmand & Amin Pourgol")
                                                .font(.custom("Nunito-SemiBold", size: 18))
                                                .foregroundColor(.nooraniTextPrimary)
                                            
                                            Spacer()
                                        }
                                        
                                        Text("Thank you for using Noorani! Feel free to connect with Amir below:")
                                            .font(.custom("Nunito-Regular", size: 14))
                                            .foregroundColor(.nooraniTextTertiary)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        
                                        // Social Links
                                        VStack(spacing: 8) {
                                            DeveloperLinkRow(
                                                icon: "globe",
                                                title: "Website",
                                                subtitle: "amir.codes",
                                                url: "https://amir.codes"
                                            )
                                            
                                            DeveloperLinkRow(
                                                icon: "camera",
                                                title: "Instagram",
                                                subtitle: "@amircodes_",
                                                url: "https://instagram.com/amircodes_"
                                            )
                                            
                                            DeveloperLinkRow(
                                                icon: "envelope",
                                                title: "Email",
                                                subtitle: "contact@amir.codes",
                                                url: "mailto:contact@amir.codes"
                                            )
                                        }
                                    }
                                    .padding(.all, 20)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(Color.white)
                                            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
                                    )
                                }
                                .padding(.horizontal, 20)
                            }
                            .padding(.top, 30)

                            // Attributions Section
                            VStack(alignment: .leading, spacing: 15) {
                                Text("Attributions")
                                    .font(.custom("Nunito-SemiBold", size: 18))
                                    .foregroundColor(.nooraniTextSecondary)
                                    .padding(.horizontal, 20)

                                VStack(spacing: 12) {
                                    VStack(spacing: 10) {
                                        Text("Icons used in this app are provided by:")
                                            .font(.custom("Nunito-Regular", size: 14))
                                            .foregroundColor(.nooraniTextTertiary)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        
                                        VStack(alignment: .leading, spacing: 8) {
                                            AttributionLinkRow(
                                                title: "Makkah icons by rimsha-ibrar",
                                                url: "https://www.flaticon.com/free-icons/makkah"
                                            )
                                            
                                            AttributionLinkRow(
                                                title: "Islamic icons by Atif Arshad",
                                                url: "https://www.flaticon.com/free-icons/islamic"
                                            )
                                            
                                            AttributionLinkRow(
                                                title: "Quran icon by VectorPortal",
                                                url: "https://www.freepik.com/icon/prophet_10031075#fromView=search&page=1&position=28&uuid=3edb6063-725b-4da0-82be-676f18042121"
                                            )
                                        }
                                    }
                                    .padding(.all, 20)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(Color.white)
                                            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
                                    )
                                }
                                .padding(.horizontal, 20)
                            }
                            .padding(.top, 30)
                            .padding(.bottom, 30)

                        }
                    }

                    Spacer()
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(for: String.self) { destination in
                switch destination {
                case "PrivacyPolicy":
                    PrivacyPolicyView()
                case "TermsOfService":
                    TermsOfServiceView()
                default:
                    EmptyView()
                }
            }
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




}

struct AboutInfoRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .font(.custom("Nunito-Regular", size: 16))
                .foregroundColor(.nooraniTextPrimary)

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
                    .foregroundColor(.nooraniPrimary)
                    .font(.system(size: 16))
                    .frame(width: 20)

                Text(title)
                    .font(.custom("Nunito-Regular", size: 16))
                    .foregroundColor(.nooraniTextPrimary)
                    .padding(.leading, 8)

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.nooraniPrimary)
                    .font(.system(size: 16, weight: .medium))
            }
            .padding(.vertical, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct DeveloperLinkRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let url: String
    @State private var showingEmailOptions = false
    
    var body: some View {
        Button(action: {
            if title == "Email" {
                showingEmailOptions = true
            } else {
                openURL(url)
            }
        }) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.nooraniPrimary)
                    .frame(width: 20, alignment: .center)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.custom("Nunito-Medium", size: 14))
                        .foregroundColor(.nooraniTextPrimary)
                    
                    Text(subtitle)
                        .font(.custom("Nunito-Regular", size: 13))
                        .foregroundColor(.nooraniTextTertiary)
                }
                
                Spacer()
                
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.nooraniPrimary.opacity(0.7))
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .confirmationDialog("Choose Email App", isPresented: $showingEmailOptions) {
            Button("Mail App") {
                if let url = URL(string: "mailto:contact@amir.codes") {
                    UIApplication.shared.open(url)
                }
            }
            
            Button("Gmail") {
                if let url = URL(string: "googlegmail://co?to=contact@amir.codes") {
                    UIApplication.shared.open(url)
                } else {
                    // Fallback to Gmail web if app not installed
                    if let url = URL(string: "https://mail.google.com/mail/?view=cm&to=contact@amir.codes") {
                        UIApplication.shared.open(url)
                    }
                }
            }
            
            Button("Cancel", role: .cancel) { }
        }
    }
    
    private func openURL(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url)
    }
}

struct AttributionLinkRow: View {
    let title: String
    let url: String
    
    var body: some View {
        Button(action: {
            openURL(url)
        }) {
            HStack(spacing: 8) {
                Image(systemName: "link")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.nooraniPrimary.opacity(0.7))
                
                Text(title)
                    .font(.custom("Nunito-Regular", size: 13))
                    .foregroundColor(.nooraniTextTertiary)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.nooraniPrimary.opacity(0.6))
            }
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func openURL(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url)
    }
}

#Preview {
    AboutView()
}
