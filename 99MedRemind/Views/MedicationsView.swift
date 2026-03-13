//
//  MedicationsView.swift
//  99MedRemind
//
//  Created by Fedele Avella on 09.03.2026.
//
//
import SwiftUI

struct MedicationsView: View {
    @ObservedObject var viewModel: MedRemindViewModel
    @State private var showingAddMedication = false
    @State private var searchText: String = ""

    var body: some View {
        ZStack {
            LinearGradient.medBackground
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("My medications")
                            .foregroundColor(.medUpcoming)
                            .font(.largeTitle)
                            .bold()

                        Text("\(viewModel.medications.count) total")
                            .foregroundColor(.white.opacity(0.6))
                            .font(.caption)
                    }

                    Spacer()

                    Button {
                        showingAddMedication = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.medUpcoming)
                            .shadow(color: .black.opacity(0.4), radius: 8, x: 0, y: 5)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 16)

                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredMedications) { medication in
                            MedicationCard(medication: medication, viewModel: viewModel)
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        viewModel.deleteMedication(medication)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }

                                    Button {
                                        viewModel.toggleActive(medication)
                                    } label: {
                                        Label(
                                            medication.isActive ? "Disable" : "Enable",
                                            systemImage: "power"
                                        )
                                    }
                                    .tint(.medUpcoming)
                                }
                        }
                    }
                    .padding()
                }
            }
        }
        .sheet(isPresented: $showingAddMedication) {
            AddMedicationView(viewModel: viewModel)
        }
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .automatic), prompt: "Search medications")
    }

    private var filteredMedications: [Medication] {
        let sorted = viewModel.medications.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return sorted
        }
        let query = searchText.lowercased()
        return sorted.filter { med in
            if med.name.lowercased().contains(query) { return true }
            if let purpose = med.purpose?.lowercased(), purpose.contains(query) { return true }
            if let notes = med.notes?.lowercased(), notes.contains(query) { return true }
            if let instructions = med.instructions?.lowercased(), instructions.contains(query) { return true }
            return false
        }
    }
}

