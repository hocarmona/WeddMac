//
//  Guest.swift
//  WeddMac
//
//  Created by Hector Carmona on 5/4/26.
//

import Foundation
import SwiftData

@Model
final class Guest {
    var id: UUID
    var name: String
    var email: String?
    var phone: String?
    var plusOnes: Int
    var dietaryRestrictions: String?
    var rsvpStatus: RSVPStatus
    var tableNumber: Int?
    var notes: String?
    var createdAt: Date

    init(
        name: String,
        email: String? = nil,
        phone: String? = nil,
        plusOnes: Int = 0,
        dietaryRestrictions: String? = nil,
        rsvpStatus: RSVPStatus = .pending,
        tableNumber: Int? = nil,
        notes: String? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.email = email
        self.phone = phone
        self.plusOnes = plusOnes
        self.dietaryRestrictions = dietaryRestrictions
        self.rsvpStatus = rsvpStatus
        self.tableNumber = tableNumber
        self.notes = notes
        self.createdAt = Date()
    }

    var totalSeats: Int {
        1 + plusOnes
    }
}

enum RSVPStatus: String, Codable, CaseIterable, Identifiable {
    case pending
    case confirmed
    case declined

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .pending:   return "Pendiente"
        case .confirmed: return "Confirmado"
        case .declined:  return "No asiste"
        }
    }

    var symbol: String {
        switch self {
        case .pending:   return "questionmark.circle"
        case .confirmed: return "checkmark.circle.fill"
        case .declined:  return "xmark.circle.fill"
        }
    }
}
