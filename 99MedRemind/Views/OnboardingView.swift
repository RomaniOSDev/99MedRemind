//
//  OnboardingView.swift
//  99MedRemind
//
//  Created by Fedele Avella on 09.03.2026.
//
//
import SwiftUI

struct OnboardingView: View {
    @Binding var isPresented: Bool
    @Binding var hasSeenOnboarding: Bool

    @State private var currentPage: Int = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            title: "Welcome to MedRemind",
            subtitle: "Keep your medications and supplements organized in one clean, minimal app.",
            systemImage: "cross.case.fill"
        ),
        OnboardingPage(
            title: "Never miss a dose",
            subtitle: "Create smart schedules and get local notifications right on time.",
            systemImage: "alarm.fill"
        ),
        OnboardingPage(
            title: "Track adherence",
            subtitle: "See your daily progress, history, and statistics to stay on track.",
            systemImage: "chart.bar.doc.horizontal.fill"
        )
    ]

    var body: some View {
        ZStack {
            LinearGradient.medBackground
                .ignoresSafeArea()

            VStack {
                HStack {
                    Spacer()
                    Button("Skip") {
                        completeOnboarding()
                    }
                    .foregroundColor(.white.opacity(0.7))
                    .font(.caption)
                    .padding(.top, 16)
                    .padding(.trailing, 20)
                }

                Spacer()

                TabView(selection: $currentPage) {
                    ForEach(pages.indices, id: \.self) { index in
                        OnboardingPageView(page: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))

                Spacer()

                Button(action: nextOrComplete) {
                    Text(currentPage == pages.count - 1 ? "Get started" : "Next")
                        .foregroundColor(.black)
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(LinearGradient.medAccent)
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.5), radius: 12, x: 0, y: 8)
                        .padding(.horizontal, 32)
                        .padding(.bottom, 32)
                }
            }
        }
    }

    private func nextOrComplete() {
        if currentPage < pages.count - 1 {
            withAnimation {
                currentPage += 1
            }
        } else {
            completeOnboarding()
        }
    }

    private func completeOnboarding() {
        hasSeenOnboarding = true
        isPresented = false
    }
}

private struct OnboardingPage {
    let title: String
    let subtitle: String
    let systemImage: String
}

private struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(LinearGradient.medCard)
                    .frame(width: 180, height: 180)
                    .shadow(color: .black.opacity(0.5), radius: 18, x: 0, y: 12)

                Image(systemName: page.systemImage)
                    .font(.system(size: 72))
                    .foregroundColor(.medUpcoming)
            }

            VStack(spacing: 12) {
                Text(page.title)
                    .foregroundColor(.white)
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)

                Text(page.subtitle)
                    .foregroundColor(.white.opacity(0.7))
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()
        }
    }
}

