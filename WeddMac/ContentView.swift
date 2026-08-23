//
//  ContentView.swift
//  WeddMac
//
//  Created by Hector Carmona on 5/4/26.
//

import SwiftUI
import SwiftData

enum AppSection: String, CaseIterable, Identifiable, Hashable {
    case vendors
    case budget
    case documents
    case guests
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .vendors:   return "Proveedores"
        case .budget:    return "Presupuesto"
        case .documents: return "Documentos"
        case .guests:    return "Invitados"
        case .settings:  return "Ajustes"
        }
    }

    var symbol: String {
        switch self {
        case .vendors:   return "person.2"
        case .budget:    return "chart.pie"
        case .documents: return "doc.text"
        case .guests:    return "person.3"
        case .settings:  return "gear"
        }
    }
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var weddings: [Wedding]

    @State private var selectedSection: AppSection = .vendors

    var body: some View {
        NavigationSplitView {
            List(AppSection.allCases) { section in
                Button {
                    selectedSection = section
                } label: {
                    Label(section.title, systemImage: section.symbol)
                }
                .buttonStyle(.plain)
                .listRowBackground(
                    selectedSection == section
                        ? Color.accentColor.opacity(0.16)
                        : Color.clear
                )
            }
            .navigationTitle("Wedding")
            .frame(minWidth: 180)
        } detail: {
            Group {
                switch selectedSection {
                case .vendors:   VendorsView()
                case .budget:    BudgetView()
                case .documents: DocumentsView()
                case .guests:    GuestsView()
                case .settings:  SettingsView()
                }
            }
            .frame(minWidth: 320)
        }
        .onAppear {
            ensureWeddingExists()
        }
    }

    private func ensureWeddingExists() {
        guard weddings.isEmpty else { return }
        let wedding = Wedding()
        modelContext.insert(wedding)
        try? modelContext.save()
    }
}

#Preview {
    ContentView()
        .modelContainer(
            for: [
                Wedding.self,
                Vendor.self,
                Payment.self,
                Contract.self,
                Guest.self
            ],
            inMemory: true
        )
}
