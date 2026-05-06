//
//  Vendor.swift
//  WeddMac
//
//  Created by Hector Carmona on 5/4/26.
//

import Foundation
import SwiftData

@Model
final class Vendor {
    var id: UUID
    var name: String
    var category: VendorCategory
    var contractTotal: Decimal
    var currency: String

    var contactName: String?
    var contactPhone: String?
    var contactEmail: String?
    var notes: String?
    var contractDate: Date?
    var serviceDate: Date?

    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \Payment.vendor)
    var payments: [Payment] = []

    @Relationship(deleteRule: .cascade, inverse: \Contract.vendor)
    var contracts: [Contract] = []

    init(
        name: String,
        category: VendorCategory,
        contractTotal: Decimal,
        currency: String = "MXN",
        contactName: String? = nil,
        contactPhone: String? = nil,
        contactEmail: String? = nil,
        notes: String? = nil,
        contractDate: Date? = nil,
        serviceDate: Date? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.category = category
        self.contractTotal = contractTotal
        self.currency = currency
        self.contactName = contactName
        self.contactPhone = contactPhone
        self.contactEmail = contactEmail
        self.notes = notes
        self.contractDate = contractDate
        self.serviceDate = serviceDate
        self.createdAt = Date()
    }

    var totalPaid: Decimal {
        payments.reduce(Decimal(0)) { $0 + $1.amount }
    }

    var balance: Decimal {
        contractTotal - totalPaid
    }

    var paymentStatus: PaymentStatus {
        if totalPaid == 0 { return .pending }
        if balance <= 0 { return .paid }
        return .partial
    }
}

enum VendorCategory: String, Codable, CaseIterable, Identifiable {
    case venue
    case photographer
    case videographer
    case music
    case decoration
    case catering
    case cake
    case attire
    case transport
    case planner
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .venue:        return "Salón"
        case .photographer: return "Fotógrafo"
        case .videographer: return "Video"
        case .music:        return "Música"
        case .decoration:   return "Decoración"
        case .catering:     return "Banquete"
        case .cake:         return "Pastel"
        case .attire:       return "Vestido/Traje"
        case .transport:    return "Transporte"
        case .planner:      return "Wedding Planner"
        case .other:        return "Otro"
        }
    }

    var symbol: String {
        switch self {
        case .venue:        return "building.columns"
        case .photographer: return "camera"
        case .videographer: return "video"
        case .music:        return "music.note"
        case .decoration:   return "leaf"
        case .catering:     return "fork.knife"
        case .cake:         return "birthday.cake"
        case .attire:       return "tshirt"
        case .transport:    return "car"
        case .planner:      return "person.crop.rectangle.stack"
        case .other:        return "tag"
        }
    }
}

enum PaymentStatus: String, Codable {
    case pending
    case partial
    case paid

    var displayName: String {
        switch self {
        case .pending: return "Pendiente"
        case .partial: return "Parcial"
        case .paid:    return "Pagado"
        }
    }
}
