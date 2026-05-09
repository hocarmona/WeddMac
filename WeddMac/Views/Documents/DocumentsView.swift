//
//  DocumentsView.swift
//  WeddMac
//

import SwiftUI
import SwiftData
import AppKit
internal import UniformTypeIdentifiers

struct DocumentsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Contract.uploadedDate, order: .reverse) private var allContracts: [Contract]

    @State private var selectedContract: Contract?
    @State private var contractToDelete: Contract?
    @State private var showingDeleteAlert = false

    // Group contracts by vendor, vendors with no name go to "Sin proveedor"
    private var grouped: [(vendorName: String, contracts: [Contract])] {
        let dict = Dictionary(grouping: allContracts) { $0.vendor?.name ?? "Sin proveedor" }
        return dict
            .map { (vendorName: $0.key, contracts: $0.value) }
            .sorted { $0.vendorName < $1.vendorName }
    }

    var body: some View {
        Group {
            if allContracts.isEmpty {
                emptyState
            } else {
                List(selection: $selectedContract) {
                    ForEach(grouped, id: \.vendorName) { group in
                        Section(group.vendorName) {
                            ForEach(group.contracts) { contract in
                                ContractRowView(contract: contract)
                                    .tag(contract)
                                    .contextMenu {
                                        Button("Abrir") { selectedContract = contract }
                                        Button("Exportar") { exportContract(contract) }
                                        Divider()
                                        Button("Eliminar", role: .destructive) {
                                            contractToDelete = contract
                                            showingDeleteAlert = true
                                        }
                                    }
                            }
                        }
                    }
                }
                .listStyle(.sidebar)
                .onChange(of: selectedContract) { _, new in
                    // open viewer when selection changes via keyboard or click
                }
            }
        }
        .navigationTitle("Documentos")
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Text("\(allContracts.count) archivos")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .sheet(item: $selectedContract) { contract in
            PDFViewerSheet(contract: contract)
        }
        .alert("¿Eliminar documento?", isPresented: $showingDeleteAlert) {
            Button("Cancelar", role: .cancel) { contractToDelete = nil }
            Button("Eliminar", role: .destructive) { deleteContract() }
        } message: {
            Text("Se eliminara \"\(contractToDelete?.fileName ?? "")\". Esta accion no se puede deshacer.")
        }
    }

    private var emptyState: some View {
        ContentUnavailableView(
            "Sin documentos",
            systemImage: "doc.fill",
            description: Text("Adjunta contratos PDF desde la vista de cada proveedor.")
        )
    }

    @MainActor
    private func exportContract(_ contract: Contract) {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.pdf]
        panel.nameFieldStringValue = contract.fileName
        panel.canCreateDirectories = true
        if panel.runModal() == .OK, let url = panel.url {
            try? contract.fileData.write(to: url)
        }
    }

    private func deleteContract() {
        guard let contract = contractToDelete else { return }
        context.delete(contract)
        try? context.save()
        contractToDelete = nil
    }
}
