//
//  DocumentsView.swift
//  WeddMac
//

import SwiftUI
import SwiftData
import AppKit
import PDFKit
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

struct ContractRowView: View {
    let contract: Contract

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "doc.fill")
                .font(.title2)
                .foregroundStyle(.red)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(contract.fileName)
                    .font(.body)
                    .lineLimit(1)
                    .truncationMode(.middle)

                Text(contract.uploadedDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(fileSize)
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }

    private var fileSize: String {
        let kilobytes = Double(contract.fileData.count) / 1024.0
        if kilobytes >= 1024 {
            return String(format: "%.1f MB", kilobytes / 1024)
        }
        return String(format: "%.0f KB", kilobytes)
    }
}

struct PDFViewerSheet: View {
    let contract: Contract
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Text(contract.fileName)
                    .font(.headline)
                    .lineLimit(1)
                    .truncationMode(.middle)

                Spacer()

                Button(action: exportPDF) {
                    Label("Exportar", systemImage: "square.and.arrow.down")
                }

                Button("Cerrar") {
                    dismiss()
                }
                .keyboardShortcut(.escape)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.bar)

            Divider()

            PDFKitView(data: contract.fileData)
                .frame(minWidth: 600, minHeight: 700)
        }
        .frame(minWidth: 620, minHeight: 740)
    }

    @MainActor
    private func exportPDF() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.pdf]
        panel.nameFieldStringValue = contract.fileName
        panel.canCreateDirectories = true

        if panel.runModal() == .OK, let url = panel.url {
            try? contract.fileData.write(to: url)
        }
    }
}

struct PDFKitView: NSViewRepresentable {
    let data: Data

    func makeNSView(context: Context) -> PDFView {
        let view = PDFView()
        view.autoScales = true
        view.displayMode = .singlePageContinuous
        view.displayDirection = .vertical
        return view
    }

    func updateNSView(_ nsView: PDFView, context: Context) {
        nsView.document = PDFDocument(data: data)
    }
}
