//
//  SettingsView.swift
//  WeddMac
//
//  Created by Hector Carmona on 5/5/26.
//

import SwiftUI
import SwiftData
import AppKit
internal import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext

    @Query private var weddings: [Wedding]
    @Query private var vendors: [Vendor]
    @Query private var payments: [Payment]
    @Query private var contracts: [Contract]
    @Query private var guests: [Guest]

    @State private var showResetStep1 = false
    @State private var showResetStep2 = false
    @State private var resetConfirmationText = ""

    @State private var statusMessage: String?
    @State private var statusIsError = false

    private let currencyOptions = ["MXN", "USD", "EUR"]

    var body: some View {
        Group {
            if let wedding = weddings.first {
                Form {
                    weddingSection(wedding: wedding)
                    dataManagementSection
                    statsSection
                    dangerZoneSection
                }
                .formStyle(.grouped)
            } else {
                ContentUnavailableView(
                    "Sin Boda",
                    systemImage: "heart.slash",
                    description: Text("No se encontró la configuración de boda.")
                )
            }
        }
        .navigationTitle("Ajustes")
        .alert(
            statusIsError ? "Error" : "Listo",
            isPresented: Binding(
                get: { statusMessage != nil },
                set: { if !$0 { statusMessage = nil } }
            )
        ) {
            Button("OK") { statusMessage = nil }
        } message: {
            Text(statusMessage ?? "")
        }
        .alert("¿Borrar todos los datos?", isPresented: $showResetStep1) {
            Button("Cancelar", role: .cancel) { }
            Button("Continuar", role: .destructive) {
                showResetStep2 = true
            }
        } message: {
            Text("Esta acción borrará TODOS los proveedores, pagos, contratos e invitados. No se puede deshacer.")
        }
        .sheet(isPresented: $showResetStep2) {
            resetConfirmationSheet
        }
    }

    // MARK: - Wedding Section

    @ViewBuilder
    private func weddingSection(wedding: Wedding) -> some View {
        @Bindable var bindable = wedding
        Section("Boda") {
            TextField("Nombre", text: $bindable.name)
            DatePicker("Fecha", selection: $bindable.date, displayedComponents: [.date, .hourAndMinute])
            TextField(
                "Presupuesto Total",
                value: $bindable.totalBudget,
                format: .currency(code: wedding.defaultCurrency)
            )
            Picker("Moneda", selection: $bindable.defaultCurrency) {
                ForEach(currencyOptions, id: \.self) { code in
                    Text(code).tag(code)
                }
            }
        }
    }

    // MARK: - Data Management Section

    private var dataManagementSection: some View {
        Section("Gestión de Datos") {
            Button {
                exportAllDataAsJSON()
            } label: {
                Label("Exportar Todos los Datos a JSON", systemImage: "square.and.arrow.up")
            }

            Button {
                exportAllPDFs()
            } label: {
                Label("Exportar PDFs", systemImage: "doc.on.doc")
            }
        }
    }

    // MARK: - Stats Section

    private var statsSection: some View {
        Section("Estadísticas") {
            statRow(label: "Proveedores", value: "\(vendors.count)")
            statRow(label: "Pagos", value: "\(payments.count)")
            statRow(label: "Invitados", value: "\(guests.count)")
            statRow(label: "Documentos", value: "\(contracts.count)")
            statRow(label: "Espacio usado por PDFs", value: pdfStorageSizeFormatted)
        }
    }

    private func statRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(value).foregroundStyle(.secondary)
        }
    }

    private var pdfStorageSizeFormatted: String {
        let totalBytes = contracts.reduce(0) { $0 + $1.fileData.count }
        let mb = Double(totalBytes) / (1024.0 * 1024.0)
        return String(format: "%.2f MB", mb)
    }

    // MARK: - Danger Zone Section

    private var dangerZoneSection: some View {
        Section("Zona de Peligro") {
            Button(role: .destructive) {
                showResetStep1 = true
            } label: {
                Label("Borrar Todos los Datos", systemImage: "trash")
                    .foregroundStyle(.red)
            }
        }
    }

    private var resetConfirmationSheet: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Confirmación final")
                .font(.title2.bold())

            Text("Para confirmar, escribe **BORRAR** en el campo. Esta acción es irreversible y eliminará proveedores, pagos, contratos e invitados.")
                .font(.callout)
                .fixedSize(horizontal: false, vertical: true)

            TextField("Escribe BORRAR", text: $resetConfirmationText)
                .textFieldStyle(.roundedBorder)

            HStack {
                Spacer()
                Button("Cancelar") {
                    showResetStep2 = false
                    resetConfirmationText = ""
                }
                Button("Borrar Todo", role: .destructive) {
                    resetAllData()
                    showResetStep2 = false
                    resetConfirmationText = ""
                }
                .disabled(resetConfirmationText != "BORRAR")
            }
        }
        .padding(24)
        .frame(width: 440)
    }

    // MARK: - Actions

    private func exportAllDataAsJSON() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "weddmac-export-\(Self.timestamp).json"
        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            let snapshot = ExportSnapshot.build(
                wedding: weddings.first,
                vendors: vendors,
                payments: payments,
                contracts: contracts,
                guests: guests
            )
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(snapshot)
            try data.write(to: url)
            statusIsError = false
            statusMessage = "Datos exportados a \(url.lastPathComponent)"
        } catch {
            statusIsError = true
            statusMessage = error.localizedDescription
        }
    }

    private func exportAllPDFs() {
        guard !contracts.isEmpty else {
            statusIsError = false
            statusMessage = "No hay PDFs para exportar."
            return
        }

        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Elegir Carpeta"
        guard panel.runModal() == .OK, let folder = panel.url else { return }

        let rootName = "WeddMac PDFs \(Self.timestamp)"
        let root = folder.appendingPathComponent(rootName, isDirectory: true)
        let fm = FileManager.default

        do {
            try fm.createDirectory(at: root, withIntermediateDirectories: true)
            var savedCount = 0
            for contract in contracts {
                let vendorName = contract.vendor?.name ?? "Sin Proveedor"
                let vendorDir = root.appendingPathComponent(sanitizeFileName(vendorName), isDirectory: true)
                try fm.createDirectory(at: vendorDir, withIntermediateDirectories: true)

                let target = vendorDir.appendingPathComponent(sanitizeFileName(contract.fileName))
                try contract.fileData.write(to: uniqueURL(for: target))
                savedCount += 1
            }
            statusIsError = false
            statusMessage = "Se exportaron \(savedCount) PDFs a \(root.lastPathComponent)"
        } catch {
            statusIsError = true
            statusMessage = error.localizedDescription
        }
    }

    private func resetAllData() {
        for guest in guests { modelContext.delete(guest) }
        for contract in contracts { modelContext.delete(contract) }
        for payment in payments { modelContext.delete(payment) }
        for vendor in vendors { modelContext.delete(vendor) }

        if let wedding = weddings.first {
            wedding.name = "Mi Boda"
            wedding.date = Calendar.current.date(byAdding: .month, value: 6, to: .now) ?? .now
            wedding.totalBudget = 0
            wedding.defaultCurrency = "MXN"
        }

        try? modelContext.save()
        statusIsError = false
        statusMessage = "Todos los datos fueron borrados."
    }

    // MARK: - Helpers

    private static var timestamp: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd-HHmmss"
        return f.string(from: Date())
    }

    private func sanitizeFileName(_ name: String) -> String {
        let invalid = CharacterSet(charactersIn: "/\\?%*|\"<>:")
        let cleaned = name.components(separatedBy: invalid).joined(separator: "_")
        return cleaned.isEmpty ? "Untitled" : cleaned
    }

    private func uniqueURL(for url: URL) -> URL {
        let fm = FileManager.default
        guard fm.fileExists(atPath: url.path) else { return url }
        let dir = url.deletingLastPathComponent()
        let base = url.deletingPathExtension().lastPathComponent
        let ext = url.pathExtension
        var i = 1
        while true {
            let name = ext.isEmpty ? "\(base) (\(i))" : "\(base) (\(i)).\(ext)"
            let candidate = dir.appendingPathComponent(name)
            if !fm.fileExists(atPath: candidate.path) { return candidate }
            i += 1
        }
    }
}

// MARK: - Export DTOs

private struct ExportSnapshot: Codable {
    let exportedAt: Date
    let wedding: WeddingDTO?
    let vendors: [VendorDTO]
    let payments: [PaymentDTO]
    let contracts: [ContractDTO]
    let guests: [GuestDTO]

    @MainActor
    static func build(
        wedding: Wedding?,
        vendors: [Vendor],
        payments: [Payment],
        contracts: [Contract],
        guests: [Guest]
    ) -> ExportSnapshot {
        ExportSnapshot(
            exportedAt: Date(),
            wedding: wedding.map(WeddingDTO.init),
            vendors: vendors.map(VendorDTO.init),
            payments: payments.map(PaymentDTO.init),
            contracts: contracts.map(ContractDTO.init),
            guests: guests.map(GuestDTO.init)
        )
    }
}

private struct WeddingDTO: Codable {
    let id: UUID
    let name: String
    let date: Date
    let totalBudget: Decimal
    let defaultCurrency: String

    init(_ w: Wedding) {
        self.id = w.id
        self.name = w.name
        self.date = w.date
        self.totalBudget = w.totalBudget
        self.defaultCurrency = w.defaultCurrency
    }
}

private struct VendorDTO: Codable {
    let id: UUID
    let name: String
    let category: String
    let contractTotal: Decimal
    let currency: String
    let contactName: String?
    let contactPhone: String?
    let contactEmail: String?
    let notes: String?
    let contractDate: Date?
    let serviceDate: Date?
    let createdAt: Date

    init(_ v: Vendor) {
        self.id = v.id
        self.name = v.name
        self.category = v.category.rawValue
        self.contractTotal = v.contractTotal
        self.currency = v.currency
        self.contactName = v.contactName
        self.contactPhone = v.contactPhone
        self.contactEmail = v.contactEmail
        self.notes = v.notes
        self.contractDate = v.contractDate
        self.serviceDate = v.serviceDate
        self.createdAt = v.createdAt
    }
}

private struct PaymentDTO: Codable {
    let id: UUID
    let vendorId: UUID?
    let amount: Decimal
    let currency: String
    let paidDate: Date
    let dueDate: Date?
    let isPaid: Bool
    let paymentDescription: String?
    let paymentMethod: String
    let receiptFileName: String?

    init(_ p: Payment) {
        self.id = p.id
        self.vendorId = p.vendor?.id
        self.amount = p.amount
        self.currency = p.currency
        self.paidDate = p.paidDate
        self.dueDate = p.dueDate
        self.isPaid = p.isPaid
        self.paymentDescription = p.paymentDescription
        self.paymentMethod = p.paymentMethod.rawValue
        self.receiptFileName = p.receiptFileName
    }
}

private struct ContractDTO: Codable {
    let id: UUID
    let vendorId: UUID?
    let fileName: String
    let fileSizeBytes: Int
    let uploadedDate: Date
    let notes: String?

    init(_ c: Contract) {
        self.id = c.id
        self.vendorId = c.vendor?.id
        self.fileName = c.fileName
        self.fileSizeBytes = c.fileData.count
        self.uploadedDate = c.uploadedDate
        self.notes = c.notes
    }
}

private struct GuestDTO: Codable {
    let id: UUID
    let name: String
    let email: String?
    let phone: String?
    let plusOnes: Int
    let dietaryRestrictions: String?
    let rsvpStatus: String
    let tableNumber: Int?
    let notes: String?
    let createdAt: Date

    init(_ g: Guest) {
        self.id = g.id
        self.name = g.name
        self.email = g.email
        self.phone = g.phone
        self.plusOnes = g.plusOnes
        self.dietaryRestrictions = g.dietaryRestrictions
        self.rsvpStatus = g.rsvpStatus.rawValue
        self.tableNumber = g.tableNumber
        self.notes = g.notes
        self.createdAt = g.createdAt
    }
}
