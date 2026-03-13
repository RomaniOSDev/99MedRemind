//
//  Formatting.swift
//  99MedRemind
//
//  Created by Fedele Avella on 09.03.2026.
//
//
import Foundation

// Shared date formatters and helpers for MedRemind

fileprivate let medTimeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .none
    formatter.timeStyle = .short
    formatter.locale = Locale(identifier: "en_US_POSIX")
    return formatter
}()

fileprivate let medDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .none
    formatter.locale = Locale(identifier: "en_US_POSIX")
    return formatter
}()

fileprivate let medHeaderDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "EEEE, MMM d"
    formatter.locale = Locale(identifier: "en_US_POSIX")
    return formatter
}()

func formattedTime(_ date: Date) -> String {
    medTimeFormatter.string(from: date)
}

func formattedDate(_ date: Date) -> String {
    medDateFormatter.string(from: date)
}

func headerDateString(_ date: Date) -> String {
    medHeaderDateFormatter.string(from: date)
}

func statusText(_ status: DoseStatus) -> String {
    switch status {
    case .pending: return "Upcoming"
    case .taken: return "Taken"
    case .missed: return "Missed"
    case .skipped: return "Skipped"
    }
}

