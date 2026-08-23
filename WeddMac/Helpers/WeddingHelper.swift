//
//  WeddingHelper.swift
//  WeddMac
//
//  Created by Hector Carmona on 5/5/26.
//

import Foundation
import SwiftData

extension Wedding {
    static func fetchOrCreate(in context: ModelContext) -> Wedding {
        let descriptor = FetchDescriptor<Wedding>()
        if let existing = try? context.fetch(descriptor).first {
            return existing
        }
        let wedding = Wedding(
            name: "Mi Boda",
            date: Calendar.current.date(byAdding: .month, value: 6, to: .now) ?? .now,
            totalBudget: Decimal.zero,
            defaultCurrency: "MXN"
        )
        context.insert(wedding)
        try? context.save()
        return wedding
    }
}
