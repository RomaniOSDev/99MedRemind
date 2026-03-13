//
//  MedModels.swift
//  99MedRemind
//
//  Created by Fedele Avella on 09.03.2026.
//
//
import Foundation
import SwiftUI

// MARK: - Enums

enum DosageUnit: String, CaseIterable, Codable, Identifiable {
    case mg = "mg"
    case g = "g"
    case mcg = "mcg"
    case ml = "ml"
    case tablet = "tablet"
    case capsule = "capsule"
    case drop = "drop"
    case puff = "puff"
    case unit = "unit"

    var id: String { rawValue }
}

enum FrequencyType: String, CaseIterable, Codable, Identifiable {
    case once = "Once"
    case daily = "Daily"
    case weekly = "Weekly"
    case custom = "Custom"

    var id: String { rawValue }
}

enum DayOfWeek: Int, CaseIterable, Codable, Identifiable {
    case monday = 2
    case tuesday = 3
    case wednesday = 4
    case thursday = 5
    case friday = 6
    case saturday = 7
    case sunday = 1

    var id: Int { rawValue }

    var shortName: String {
        switch self {
        case .monday: return "Mon"
        case .tuesday: return "Tue"
        case .wednesday: return "Wed"
        case .thursday: return "Thu"
        case .friday: return "Fri"
        case .saturday: return "Sat"
        case .sunday: return "Sun"
        }
    }
}

enum DoseStatus {
    case pending
    case taken
    case missed
    case skipped

    var color: Color {
        switch self {
        case .pending:
            return .medUpcoming
        case .taken:
            return .medTaken
        case .missed:
            return .red
        case .skipped:
            return .gray
        }
    }

    var icon: String {
        switch self {
        case .pending:
            return "clock"
        case .taken:
            return "checkmark.circle.fill"
        case .missed:
            return "exclamationmark.circle.fill"
        case .skipped:
            return "xmark.circle.fill"
        }
    }
}

// MARK: - Core Models

struct Medication: Identifiable, Codable {
    let id: UUID
    var name: String
    var dosage: Double
    var unit: DosageUnit
    var instructions: String?
    var notes: String?
    /// Short description of why this medication is taken.
    var purpose: String?
    /// Known side effects or warnings.
    var sideEffects: String?
    /// Maximum recommended daily dose (optional, for reference only).
    var maxDailyDose: Double?
    /// Current remaining stock (tablets, capsules, ml etc. depending on unit).
    var remainingQuantity: Int?
    /// Optional threshold to consider stock low.
    var lowStockThreshold: Int?
    /// Date when medication was last refilled.
    var lastRefillDate: Date?
    var isActive: Bool
    var refillDate: Date?
    var refillReminder: Bool
    var createdAt: Date
}

struct Schedule: Identifiable, Codable {
    let id: UUID
    var medicationId: UUID
    var medicationName: String
    var times: [Date]
    var frequency: FrequencyType
    var daysOfWeek: [DayOfWeek]?
    var startDate: Date
    var endDate: Date?
    var isActive: Bool
}

struct Dose: Identifiable, Codable {
    let id: UUID
    let medicationId: UUID
    let medicationName: String
    let scheduledTime: Date
    var takenTime: Date?
    var dosage: Double
    var unit: DosageUnit
    var notes: String?
    var isSkipped: Bool

    var status: DoseStatus {
        if isSkipped {
            return .skipped
        } else if takenTime != nil {
            return .taken
        } else if scheduledTime < Date() {
            return .missed
        } else {
            return .pending
        }
    }
}

struct Refill: Identifiable, Codable {
    let id: UUID
    let medicationId: UUID
    let medicationName: String
    let date: Date
    let quantity: Int
    let notes: String?
}

struct Prescriber: Identifiable, Codable {
    let id: UUID
    var name: String
    var specialty: String?
    var phone: String?
    var clinic: String?
}

