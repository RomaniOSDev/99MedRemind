//
//  StatsView.swift
//  99MedRemind
//
//  Created by Fedele Avella on 09.03.2026.
//
//
import SwiftUI
import Charts

struct StatsView: View {
    @ObservedObject var viewModel: MedRemindViewModel

    var body: some View {
        ZStack {
            LinearGradient.medBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Statistics")
                        .foregroundColor(.medUpcoming)
                        .font(.largeTitle)
                        .bold()
                        .padding(.horizontal)
                        .padding(.top, 16)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        StatCard(
                            title: "Total doses",
                            value: "\(viewModel.totalDoses)",
                            icon: "pill.fill",
                            color: .medUpcoming
                        )

                        StatCard(
                            title: "Taken",
                            value: "\(viewModel.totalTaken)",
                            icon: "checkmark.circle.fill",
                            color: .medTaken
                        )

                        StatCard(
                            title: "Missed",
                            value: "\(viewModel.totalMissed)",
                            icon: "exclamationmark.circle.fill",
                            color: .red
                        )

                        StatCard(
                            title: "Adherence",
                            value: String(format: "%.0f%%", viewModel.adherenceRate),
                            icon: "target",
                            color: .medTaken
                        )
                    }
                    .padding(.horizontal)

                    let last7 = viewModel.stats(forLastDays: 7)
                    let last30 = viewModel.stats(forLastDays: 30)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Recent adherence")
                            .foregroundColor(.medUpcoming)
                            .font(.headline)
                            .padding(.horizontal)

                        HStack(spacing: 12) {
                            StatCard(
                                title: "Last 7 days",
                                value: last7.total > 0 ? String(format: "%.0f%%", last7.adherence) : "—",
                                icon: "7.circle",
                                color: .medUpcoming
                            )

                            StatCard(
                                title: "Last 30 days",
                                value: last30.total > 0 ? String(format: "%.0f%%", last30.adherence) : "—",
                                icon: "30.circle",
                                color: .medUpcoming
                            )
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 8)
                    .background(LinearGradient.medCard)
                    .cornerRadius(14)
                    .shadow(color: .black.opacity(0.35), radius: 10, x: 0, y: 6)
                    .padding(.horizontal)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Adherence by month")
                            .foregroundColor(.medUpcoming)
                            .font(.headline)
                            .padding(.horizontal)

                        Chart {
                            ForEach(viewModel.monthlyAdherence, id: \.month) { data in
                                BarMark(
                                    x: .value("Month", data.month),
                                    y: .value("Adherence", data.adherence)
                                )
                                .foregroundStyle(Color.medTaken)
                            }
                        }
                        .frame(height: 200)
                        .padding()
                    }
                    .background(LinearGradient.medCard)
                    .cornerRadius(14)
                    .shadow(color: .black.opacity(0.35), radius: 10, x: 0, y: 6)
                    .padding(.horizontal)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("By medication")
                            .foregroundColor(.medUpcoming)
                            .font(.headline)
                            .padding(.horizontal)

                        ForEach(viewModel.medicationStats.prefix(5)) { stat in
                            HStack {
                                Text(stat.name)
                                    .foregroundColor(.white)

                                Spacer()

                                Text("\(stat.takenCount)/\(stat.totalCount)")
                                    .foregroundColor(.medTaken)

                                Text("(\(Int(stat.adherence))%)")
                                    .foregroundColor(.gray)
                                    .font(.caption)
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 4)
                        }
                    }
                    .padding(.vertical)
                    .background(LinearGradient.medCard)
                    .cornerRadius(14)
                    .shadow(color: .black.opacity(0.35), radius: 10, x: 0, y: 6)
                    .padding(.horizontal)

                    Spacer(minLength: 24)
                }
            }
        }
    }
}

