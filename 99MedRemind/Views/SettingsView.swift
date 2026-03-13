//
//  SettingsView.swift
//  99MedRemind
//
//  Created by Fedele Avella on 09.03.2026.
//
//
import SwiftUI
import StoreKit
import UIKit

struct SettingsView: View {
    @ObservedObject var viewModel: MedRemindViewModel

    var body: some View {
        ZStack {
            LinearGradient.medBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header

                    mainSection

                    aboutSection

                    Spacer(minLength: 24)
                }
                .padding(.top, 8)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Settings")
                .foregroundColor(.medUpcoming)
                .font(.largeTitle)
                .bold()

            Text("Customize your MedRemind experience.")
                .foregroundColor(.white.opacity(0.7))
                .font(.caption)
        }
        .padding(.horizontal)
        .padding(.top, 16)
    }

    private var mainSection: some View {
        VStack(spacing: 12) {
            SettingsRow(
                icon: "star.fill",
                iconColor: .yellow,
                title: "Rate MedRemind",
                subtitle: "Share your feedback on the App Store"
            ) {
                rateApp()
            }

            SettingsRow(
                icon: "lock.shield.fill",
                iconColor: .medUpcoming,
                title: "Privacy Policy",
                subtitle: "How we handle your data"
            ) {
                open(urlString: "https://www.termsfeed.com/live/aa37a9fe-3b12-4345-adce-366426a6f858")
            }

            SettingsRow(
                icon: "doc.text.fill",
                iconColor: .medUpcoming,
                title: "Terms of Use",
                subtitle: "Legal information about using MedRemind"
            ) {
                open(urlString: "https://www.termsfeed.com/live/1a1535aa-5a20-4290-abd3-4b3fecc9d7dc")
            }
        }
        .padding(.horizontal)
    }

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("About")
                .foregroundColor(.white)
                .font(.headline)
                .padding(.horizontal)

            VStack(alignment: .leading, spacing: 4) {
                Text("MedRemind")
                    .foregroundColor(.white)
                    .font(.subheadline)
                    .bold()

                Text("A minimal medicine and supplements tracker with smart reminders.")
                    .foregroundColor(.white.opacity(0.6))
                    .font(.caption)

                Text("Version 1.0")
                    .foregroundColor(.white.opacity(0.4))
                    .font(.caption2)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(LinearGradient.medCard)
            .cornerRadius(14)
            .shadow(color: .black.opacity(0.35), radius: 10, x: 0, y: 6)
            .padding(.horizontal)
        }
    }

    // MARK: - Actions

    private func open(urlString: String) {
        guard let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url)
    }

    private func rateApp() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: windowScene)
        }
    }
}

private struct SettingsRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(LinearGradient.medCard)
                        .frame(width: 40, height: 40)
                        .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: 4)

                    Image(systemName: icon)
                        .foregroundColor(iconColor)
                        .font(.system(size: 18, weight: .semibold))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .foregroundColor(.white)
                        .font(.subheadline)

                    Text(subtitle)
                        .foregroundColor(.white.opacity(0.6))
                        .font(.caption)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.4))
                    .font(.caption)
            }
            .padding()
            .background(LinearGradient.medCard)
            .cornerRadius(14)
            .shadow(color: .black.opacity(0.35), radius: 10, x: 0, y: 6)
        }
        .buttonStyle(.plain)
    }
}

