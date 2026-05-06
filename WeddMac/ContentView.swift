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

    @State private var selectedSection: AppSection? = .vendors
    @State private var selectedVendor: Vendor?

    var body: some View {
        NavigationSplitView {
            List(AppSection.allCases, selection: $selectedSection) { section in
                NavigationLink(value: section) {
                    Label(section.title, systemImage: section.symbol)
                }
            }
            .navigationTitle("Wedding")
            .frame(minWidth: 180)
        } content: {
            Group {
                switch selectedSection {
                case .vendors:   VendorListView(selectedVendor: $selectedVendor)
                case .budget:    BudgetView()
                case .documents: DocumentsView()
                case .guests:    GuestsView()
                case .settings:  SettingsView()
                case .none:      Text("Selecciona una sección")
                }
            }
            .frame(minWidth: 320)
        } detail: {
            detailColumn
                .frame(minWidth: 400)
        }
        .onAppear {
            ensureWeddingExists()
        }
        .onChange(of: selectedSection) { _, _ in
            selectedVendor = nil
        }
    }

    @ViewBuilder
    private var detailColumn: some View {
        switch selectedSection {
        case .vendors:
            if let vendor = selectedVendor {
                VendorDetailView(vendor: vendor)
            } else {
                ContentUnavailableView(
                    "Selecciona un proveedor",
                    systemImage: "person.2",
                    description: Text("Elige un proveedor de la lista para ver sus detalles.")
                )
            }
        default:
            Text("Selecciona un elemento")
                .foregroundStyle(.secondary)
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
        .modelContainer(for: Item.self, inMemory: true)
}
