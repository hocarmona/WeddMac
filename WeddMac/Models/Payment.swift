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
    var dueDate: Date?
    var isPaid: Bool = true
    var paymentDescription: String?
    var paymentMethod: PaymentMethod
    var receiptFileName: String?

    @Attribute(.externalStorage)
    var receiptData: Data?

    var vendor: Vendor?

    init(
        amount: Decimal,
        currency: String = "MXN",
        paidDate: Date = Date(),
        dueDate: Date? = nil,
        isPaid: Bool = true,
        paymentDescription: String? = nil,
        paymentMethod: PaymentMethod = .transfer,
        receiptFileName: String? = nil,
        receiptData: Data? = nil,
        vendor: Vendor? = nil
    ) {
        self.id = UUID()
        self.amount = amount
        self.currency = currency
        self.paidDate = paidDate
        self.dueDate = dueDate
        self.isPaid = isPaid
        self.paymentDescription = paymentDescription
        self.paymentMethod = paymentMethod
        self.receiptFileName = receiptFileName
        self.receiptData = receiptData
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
