//
//  Wedding.swift
//  WeddMac
//
//  Created by Hector Carmona on 5/4/26.
//

import Foundation
import SwiftData

@Model
final class Wedding {
    var id: UUID
    var name: String
    var date: Date
    var totalBudget: Decimal
    var defaultCurrency: String

    init(
        name: String = "Mi Boda",
        date: Date = Date().addingTimeInterval(60 * 60 * 24 * 180),
        totalBudget: Decimal = 0,
        defaultCurrency: String = "MXN"
    ) {
        self.id = UUID()
        self.name = name
        self.date = date
        self.totalBudget = totalBudget
        self.defaultCurrency = defaultCurrency
    }
}
