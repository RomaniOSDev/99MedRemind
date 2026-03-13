//
//  ContentView.swift
//  99MedRemind
//
//  Created by Fedele Avella on 09.03.2026.
//
//
import SwiftUI
import UserNotifications

/// Root tab-based entry point for MedRemind.
struct ContentView: View {
    @StateObject private var viewModel = MedRemindViewModel()
    @State private var selectedTab = 0
    @AppStorage("medremind_has_seen_onboarding") private var hasSeenOnboarding: Bool = false
    @State private var showOnboarding: Bool = false

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(viewModel: viewModel)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)

            TodayView(viewModel: viewModel)
                .tabItem {
                    Label("Today", systemImage: "calendar")
                }
                .tag(1)

            MedicationsView(viewModel: viewModel)
                .tabItem {
                    Label("Medications", systemImage: "pill.fill")
                }
                .tag(2)

            HistoryView(viewModel: viewModel)
                .tabItem {
                    Label("History", systemImage: "clock.arrow.circlepath")
                }
                .tag(3)

            StatsView(viewModel: viewModel)
                .tabItem {
                    Label("Stats", systemImage: "chart.bar.fill")
                }
                .tag(4)

            SettingsView(viewModel: viewModel)
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(5)
        }
        .preferredColorScheme(.dark)
        .onAppear {
            viewModel.loadFromUserDefaults()
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
            if !hasSeenOnboarding {
                showOnboarding = true
            }
        }
        .tint(.medUpcoming)
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView(isPresented: $showOnboarding, hasSeenOnboarding: $hasSeenOnboarding)
        }
    }
}

#Preview {
    ContentView()
}

