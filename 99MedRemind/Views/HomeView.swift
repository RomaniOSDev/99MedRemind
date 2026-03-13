//
//  HomeView.swift
//  99MedRemind
//
//  Created by Fedele Avella on 09.03.2026.
//
//
import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: MedRemindViewModel
    @State private var showingAddMedication = false

    var body: some View {
        ZStack {
            LinearGradient.medBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header

                    summaryCards

                    upcomingSection

                    todayPreviewSection

                    shortcutsSection

                    Spacer(minLength: 24)
                }
            }
        }
        .sheet(isPresented: $showingAddMedication) {
            AddMedicationView(viewModel: viewModel)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("MedRemind")
                .foregroundStyle(LinearGradient.medAccent)
                .font(.system(.largeTitle, design: .rounded))
                .bold()

            Text(headerDateString(Date()))
                .foregroundColor(.white.opacity(0.7))
                .font(.subheadline)

            if viewModel.todayTotal > 0 {
                let adherence = Double(viewModel.todayTaken) / Double(viewModel.todayTotal) * 100
                Text(String(format: "Today adherence: %.0f%%", adherence))
                    .foregroundColor(.medTaken)
                    .font(.caption)
            } else {
                Text("No doses scheduled for today")
                    .foregroundColor(.gray)
                    .font(.caption)
            }
        }
        .padding(.horizontal)
        .padding(.top, 24)
    }

    private var summaryCards: some View {
        let last7 = viewModel.stats(forLastDays: 7)
        let activeMeds = viewModel.medications.filter { $0.isActive }
        let lowStockCount = activeMeds.filter { med in
            if let remaining = med.remainingQuantity {
                if let threshold = med.lowStockThreshold {
                    return remaining <= threshold
                }
                return remaining == 0
            }
            return false
        }.count

        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                StatCard(
                    title: "Today",
                    value: "\(viewModel.todayTaken)/\(viewModel.todayTotal)",
                    icon: "calendar",
                    color: .medUpcoming
                )

                StatCard(
                    title: "7-day adherence",
                    value: last7.total > 0 ? String(format: "%.0f%%", last7.adherence) : "—",
                    icon: "7.circle",
                    color: .medTaken
                )

                StatCard(
                    title: "Active meds",
                    value: "\(activeMeds.count)",
                    icon: "heart.fill",
                    color: .medUpcoming
                )

                StatCard(
                    title: "Low stock",
                    value: "\(lowStockCount)",
                    icon: "exclamationmark.triangle",
                    color: lowStockCount > 0 ? .red : .medUpcoming
                )
            }
            .padding(.horizontal)
        }
    }

    private var upcomingSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Next dose")
                    .foregroundColor(.white)
                    .font(.headline)

                Spacer()
            }
            .padding(.horizontal)

            if let dose = viewModel.nextUpcomingDose {
                DoseCard(dose: dose)
                    .padding(.horizontal)
            } else {
                Text("No upcoming doses")
                    .foregroundColor(.gray)
                    .font(.caption)
                    .padding(.horizontal)
            }
        }
        .padding(.vertical, 4)
    }

    private var todayPreviewSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Today's overview")
                    .foregroundColor(.white)
                    .font(.headline)

                Spacer()
            }
            .padding(.horizontal)

            if viewModel.todayDoses.isEmpty {
                Text("You have no scheduled doses today.")
                    .foregroundColor(.gray)
                    .font(.caption)
                    .padding(.horizontal)
            } else {
                ForEach(viewModel.todayDoses.prefix(3)) { dose in
                    DoseCard(dose: dose)
                        .padding(.horizontal)
                }
            }
        }
    }

    private var shortcutsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick actions")
                .foregroundColor(.white)
                .font(.headline)
                .padding(.horizontal)

            HStack(spacing: 12) {
                Button {
                    showingAddMedication = true
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                        Text("Add medication")
                            .font(.caption)
                    }
                    .foregroundStyle(Color.black)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(LinearGradient.medAccent)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.4), radius: 10, x: 0, y: 6)
                }

                VStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .font(.title2)
                    Text("Today")
                        .font(.caption)
                }
                .foregroundColor(.medUpcoming)
                .frame(maxWidth: .infinity)
                .padding()
                .background(LinearGradient.medCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.medUpcoming.opacity(0.5), lineWidth: 1)
                )
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.35), radius: 8, x: 0, y: 5)

                VStack(spacing: 8) {
                    Image(systemName: "chart.bar.fill")
                        .font(.title2)
                    Text("Stats")
                        .font(.caption)
                }
                .foregroundColor(.medUpcoming)
                .frame(maxWidth: .infinity)
                .padding()
                .background(LinearGradient.medCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.medUpcoming.opacity(0.5), lineWidth: 1)
                )
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.35), radius: 8, x: 0, y: 5)
            }
            .padding(.horizontal)
        }
        .padding(.bottom, 24)
    }
}

