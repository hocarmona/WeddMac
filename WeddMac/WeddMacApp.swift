//
//  WeddMacApp.swift
//  WeddMac
//
//  Created by Hector Carmona on 5/4/26.
//

import SwiftUI
import SwiftData

@main
struct WeddingAppV0App: App {
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(
                for: Wedding.self,
                Vendor.self,
                Payment.self,
                Contract.self,
                Guest.self
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
