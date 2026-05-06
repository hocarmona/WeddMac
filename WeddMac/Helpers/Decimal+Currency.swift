//
//  Decimal+Currency.swift
//  WeddMac
//
//  Created by Hector Carmona on 5/5/26.
//

import Foundation
import SwiftUI

extension Decimal {
    func formattedAsCurrency(code: String = "MXN") -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = code
        formatter.maximumFractionDigits = 2
        return formatter.string(from: self as NSDecimalNumber) ?? "\(self) \(code)"
    }
}

extension VendorCategory {
    var sfSymbol: String {
        switch self {
        case .venue: return "building.columns"
        case .photographer: return "camera"
        case .videographer: return "video"
        case .music: return "music.note"
        case .decoration: return "leaf"
        case .catering: return "fork.knife"
        case .cake: return "birthday.cake"
        case .attire: return "tshirt"
        case .transport: return "car"
        case .planner: return "person.2"
        case .other: return "ellipsis.circle"
        }
    }
}

extension PaymentStatus {
    var color: Color {
        switch self {
        case .pending: return .red
        case .partial: return .orange
        case .paid: return .green
        }
    }
}
