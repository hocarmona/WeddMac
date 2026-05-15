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
        Group {
            if selectedSection == .vendors {
                vendorsLayout
            } else {
                fullWidthLayout
            }
        }
        .onAppear {
            ensureWeddingExists()
        }
        .onChange(of: selectedSection) { _, _ in
            selectedVendor = nil
        }
    }
    
    // MARK: - Vendors Layout (3 columnas)
    
    private var vendorsLayout: some View {
        NavigationSplitView {
            sidebarContent
        } content: {
            VendorListView(selectedVendor: $selectedVendor)
                .frame(minWidth: 320)
        } detail: {
            if let vendor = selectedVendor {
                VendorDetailView(vendor: vendor)
                    .frame(minWidth: 400)
            } else {
                ContentUnavailableView(
                    "Selecciona un proveedor",
                    systemImage: "person.2",
                    description: Text("Elige un proveedor de la lista para ver sus detalles.")
                )
                .frame(minWidth: 400)
            }
        }
    }
    
    // MARK: - Full Width Layout (2 columnas)
    
    private var fullWidthLayout: some View {
        NavigationSplitView {
            sidebarContent
        } detail: {
            fullWidthDetailContent
        }
    }
    
    @ViewBuilder
    private var fullWidthDetailContent: some View {
        switch selectedSection {
        case .budget:
            BudgetView()
                .frame(minWidth: 600)
        case .documents:
            DocumentsView()
                .frame(minWidth: 500)
        case .guests:
            GuestsView()
                .frame(minWidth: 500)
        case .settings:
            SettingsView()
                .frame(minWidth: 500)
        default:
            Text("Selecciona una sección")
                .foregroundStyle(.secondary)
        }
    }
    
    // MARK: - Sidebar (compartido entre ambos layouts)
    
    private var sidebarContent: some View {
        List(AppSection.allCases, selection: $selectedSection) { section in
            NavigationLink(value: section) {
                Label(section.title, systemImage: section.symbol)
            }
        }
        .navigationTitle("Wedding")
        .frame(minWidth: 180)
    }

    private func ensureWeddingExists() {
        guard weddings.isEmpty else { return }
        let wedding = Wedding()
        modelContext.insert(wedding)
        try? modelContext.save()
        selectedSection = .settings
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
