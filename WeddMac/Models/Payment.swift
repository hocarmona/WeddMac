//
//  Payment.swift
//  WeddMac
//
//  Created by Hector Carmona on 5/4/26.
//

import Foundation
import SwiftData

@Model
final class Payment {
    var id: UUID
    var amount: Decimal
    var currency: String
    var paidDate: Date
    var paymentDescription: String?
    var paymentMethod: PaymentMethod

    var vendor: Vendor?

    init(
        amount: Decimal,
        currency: String = "MXN",
        paidDate: Date = Date(),
        paymentDescription: String? = nil,
        paymentMethod: PaymentMethod = .transfer,
        vendor: Vendor? = nil
    ) {
        self.id = UUID()
        self.amount = amount
        self.currency = currency
        self.paidDate = paidDate
        self.paymentDescription = paymentDescription
        self.paymentMethod = paymentMethod
        self.vendor = vendor
    }
}

enum PaymentMethod: String, Codable, CaseIterable, Identifiable {
    case cash
    case transfer
    case card
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .cash:     return "Efectivo"
        case .transfer: return "Transferencia"
        case .card:     return "Tarjeta"
        case .other:    return "Otro"
        }
    }
}
