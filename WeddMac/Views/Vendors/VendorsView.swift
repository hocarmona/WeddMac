//
//  VendorsView.swift
//  WeddMac
//
//  Created by Hector Carmona on 5/5/26.
//

import SwiftUI
import SwiftData
import AppKit
internal import UniformTypeIdentifiers

struct VendorsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Vendor.name) private var vendors: [Vendor]

    @State private var selectedVendorID: UUID?
    @State private var showingAddVendor = false
    @State private var showingEditVendor = false
    @State private var showingAddPayment = false

    private var selectedVendor: Vendor? {
        if let selectedVendorID,
           let vendor = vendors.first(where: { $0.id == selectedVendorID }) {
            return vendor
        }

        return vendors.first
    }

    var body: some View {
        HSplitView {
            vendorList
                .frame(minWidth: 280, idealWidth: 340, maxWidth: 460)

            if let selectedVendor {
                VendorDetailView(
                    vendor: selectedVendor,
                    onEditVendor: { showingEditVendor = true },
                    onAddPayment: { showingAddPayment = true },
                    onDeletePayment: deletePayment
                )
                .frame(minWidth: 460)
            } else {
                ContentUnavailableView(
                    "Sin proveedores",
                    systemImage: "person.2.slash",
                    description: Text("Agrega un proveedor para registrar contratos, abonos y saldos.")
                )
                .frame(minWidth: 460)
            }
        }
        .navigationTitle("Proveedores")
        .toolbar {
            ToolbarItem {
                Button {
                    showingAddVendor = true
                } label: {
                    Label("Nuevo proveedor", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddVendor) {
            VendorFormSheet { vendor in
                modelContext.insert(vendor)
                try? modelContext.save()
                selectedVendorID = vendor.id
            }
        }
        .sheet(isPresented: $showingEditVendor) {
            if let selectedVendor {
                VendorFormSheet(vendor: selectedVendor) { _ in
                    try? modelContext.save()
                }
            }
        }
        .sheet(isPresented: $showingAddPayment) {
            if let selectedVendor {
                PaymentFormSheet(vendor: selectedVendor) { payment in
                    modelContext.insert(payment)
                    try? modelContext.save()
                }
            }
        }
        .onAppear(perform: normalizeSelection)
        .onChange(of: vendors.map(\.id)) {
            normalizeSelection()
        }
    }

    private var vendorList: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Text("Proveedores")
                    .font(.headline)

                Spacer()

                Button {
                    showingAddVendor = true
                } label: {
                    Label("Nuevo proveedor", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()

            if vendors.isEmpty {
                ContentUnavailableView(
                    "No hay proveedores",
                    systemImage: "person.crop.circle.badge.plus",
                    description: Text("Empieza agregando el primer proveedor de la boda.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(selection: $selectedVendorID) {
                    ForEach(vendors) { vendor in
                        VendorRow(vendor: vendor)
                            .tag(Optional(vendor.id))
                    }
                    .onDelete(perform: deleteVendors)
                }
                .listStyle(.sidebar)
            }
        }
    }

    private func normalizeSelection() {
        guard !vendors.isEmpty else {
            selectedVendorID = nil
            return
        }

        if let selectedVendorID,
           vendors.contains(where: { $0.id == selectedVendorID }) {
            return
        }

        selectedVendorID = vendors.first?.id
    }

    private func deleteVendors(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(vendors[index])
        }

        try? modelContext.save()
        normalizeSelection()
    }

    private func deletePayment(_ payment: Payment) {
        modelContext.delete(payment)
        try? modelContext.save()
    }
}

private struct VendorRow: View {
    let vendor: Vendor

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: vendor.category.symbol)
                .foregroundStyle(.tint)
                .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(vendor.name)
                    .font(.headline)
                    .lineLimit(1)

                Text(vendor.category.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 4) {
                StatusBadge(status: vendor.paymentStatus)

                Text(currencyString(vendor.balance, code: vendor.currency))
                    .font(.caption)
                    .foregroundStyle(vendor.balance > 0 ? Color.secondary : Color.green)
            }
        }
        .padding(.vertical, 6)
    }
}

private struct VendorDetailView: View {
    @Environment(\.modelContext) private var modelContext

    let vendor: Vendor
    let onEditVendor: () -> Void
    let onAddPayment: () -> Void
    let onDeletePayment: (Payment) -> Void

    @State private var selectedContract: Contract?
    @State private var contractToDelete: Contract?
    @State private var showingDeleteContractAlert = false
    @State private var uploadError: String?

    private var payments: [Payment] {
        vendor.payments.sorted { first, second in
            first.paidDate > second.paidDate
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                financialSummary
                contactSection
                paymentsSection
                contractsSection
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color(nsColor: .textBackgroundColor))
        .sheet(item: $selectedContract) { contract in
            PDFViewerSheet(contract: contract)
        }
        .alert("¿Eliminar documento?", isPresented: $showingDeleteContractAlert) {
            Button("Cancelar", role: .cancel) {
                contractToDelete = nil
            }
            Button("Eliminar", role: .destructive) {
                deleteContract()
            }
        } message: {
            Text("Se eliminará \"\(contractToDelete?.fileName ?? "")\".")
        }
        .alert(
            "No se pudo adjuntar el documento",
            isPresented: Binding(
                get: { uploadError != nil },
                set: { if !$0 { uploadError = nil } }
            )
        ) {
            Button("OK", role: .cancel) {
                uploadError = nil
            }
        } message: {
            Text(uploadError ?? "Error desconocido.")
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: vendor.category.symbol)
                .font(.system(size: 28))
                .foregroundStyle(.tint)
                .frame(width: 48, height: 48)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 6) {
                Text(vendor.name)
                    .font(.title2.weight(.semibold))

                HStack(spacing: 8) {
                    Text(vendor.category.displayName)
                        .foregroundStyle(.secondary)

                    StatusBadge(status: vendor.paymentStatus)
                }
            }

            Spacer()

            Button(action: onEditVendor) {
                Label("Editar proveedor", systemImage: "pencil")
            }

            Button(action: onAddPayment) {
                Label("Registrar abono", systemImage: "plus.circle")
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var financialSummary: some View {
        Grid(alignment: .leading, horizontalSpacing: 18, verticalSpacing: 12) {
            GridRow {
                MoneyMetric(
                    title: "Contrato",
                    value: vendor.contractTotal,
                    currency: vendor.currency,
                    symbol: "doc.text"
                )

                MoneyMetric(
                    title: "Abonado",
                    value: vendor.totalPaid,
                    currency: vendor.currency,
                    symbol: "checkmark.circle"
                )

                MoneyMetric(
                    title: "Saldo",
                    value: vendor.balance,
                    currency: vendor.currency,
                    symbol: "creditcard"
                )
            }
        }
    }

    @ViewBuilder
    private var contactSection: some View {
        if vendor.contactName != nil || vendor.contactPhone != nil || vendor.contactEmail != nil || vendor.notes != nil {
            VStack(alignment: .leading, spacing: 12) {
                Text("Contacto")
                    .font(.headline)

                LabeledContent("Nombre", value: vendor.contactName ?? "Sin capturar")
                LabeledContent("Teléfono", value: vendor.contactPhone ?? "Sin capturar")
                LabeledContent("Correo", value: vendor.contactEmail ?? "Sin capturar")

                if let notes = vendor.notes, !notes.isEmpty {
                    LabeledContent("Notas", value: notes)
                }
            }
        }
    }

    private var paymentsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Abonos")
                    .font(.headline)

                Spacer()

                Button(action: onAddPayment) {
                    Label("Agregar", systemImage: "plus")
                }
            }

            if payments.isEmpty {
                ContentUnavailableView(
                    "Sin abonos",
                    systemImage: "creditcard",
                    description: Text("Registra el primer pago realizado a este proveedor.")
                )
                .frame(minHeight: 180)
            } else {
                VStack(spacing: 0) {
                    ForEach(payments) { payment in
                        PaymentRow(payment: payment, onDelete: { onDeletePayment(payment) })

                        if payment.id != payments.last?.id {
                            Divider()
                        }
                    }
                }
                .background(.background, in: RoundedRectangle(cornerRadius: 8))
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(.quaternary)
                }
            }
        }
    }

    private var contractsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Documentos")
                    .font(.headline)

                Spacer()

                Button(action: attachContract) {
                    Label("Adjuntar PDF", systemImage: "paperclip")
                }
            }

            if vendor.contracts.isEmpty {
                ContentUnavailableView(
                    "Sin documentos",
                    systemImage: "doc.badge.plus",
                    description: Text("Adjunta el contrato o cualquier documento PDF de este proveedor.")
                )
                .frame(minHeight: 150)
            } else {
                VStack(spacing: 0) {
                    ForEach(sortedContracts) { contract in
                        ContractRowView(contract: contract)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedContract = contract
                            }
                            .contextMenu {
                                Button("Abrir") {
                                    selectedContract = contract
                                }

                                Button("Eliminar", role: .destructive) {
                                    contractToDelete = contract
                                    showingDeleteContractAlert = true
                                }
                            }

                        if contract.id != sortedContracts.last?.id {
                            Divider()
                                .padding(.leading, 44)
                        }
                    }
                }
                .background(.background, in: RoundedRectangle(cornerRadius: 8))
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(.quaternary)
                }
            }
        }
    }

    private var sortedContracts: [Contract] {
        vendor.contracts.sorted { first, second in
            first.uploadedDate > second.uploadedDate
        }
    }

    @MainActor
    private func attachContract() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.pdf]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.message = "Selecciona un documento PDF"

        guard panel.runModal() == .OK, let url = panel.url else { return }

        let maximumSize = 50 * 1024 * 1024
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
              let size = attributes[.size] as? Int,
              size <= maximumSize else {
            uploadError = "El archivo supera el límite de 50 MB."
            return
        }

        do {
            let contract = Contract(
                fileName: url.lastPathComponent,
                fileData: try Data(contentsOf: url),
                vendor: vendor
            )
            modelContext.insert(contract)
            try modelContext.save()
        } catch {
            uploadError = error.localizedDescription
        }
    }

    private func deleteContract() {
        guard let contract = contractToDelete else { return }
        modelContext.delete(contract)
        try? modelContext.save()
        contractToDelete = nil
    }
}

private struct MoneyMetric: View {
    let title: String
    let value: Decimal
    let currency: String
    let symbol: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: symbol)
                    .foregroundStyle(.secondary)

                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(currencyString(value, code: currency))
                .font(.title3.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background, in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(.quaternary)
        }
    }
}

private struct PaymentRow: View {
    let payment: Payment
    let onDelete: () -> Void

    @State private var showingReceipt = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: payment.paymentMethod.symbol)
                .foregroundStyle(.tint)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(paymentTitle)
                    .font(.body)

                Text(payment.paidDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(currencyString(payment.amount, code: payment.currency))
                .font(.headline)

            if payment.receiptData != nil {
                Button {
                    showingReceipt = true
                } label: {
                    Label("Ver recibo", systemImage: "photo")
                }
                .labelStyle(.iconOnly)
                .buttonStyle(.borderless)
                .help("Ver recibo")
            }

            Button(role: .destructive, action: onDelete) {
                Label("Eliminar abono", systemImage: "trash")
            }
            .labelStyle(.iconOnly)
            .buttonStyle(.borderless)
        }
        .padding(12)
        .sheet(isPresented: $showingReceipt) {
            if let data = payment.receiptData {
                ReceiptPreviewSheet(
                    fileName: payment.receiptFileName ?? "Recibo",
                    data: data
                )
            }
        }
    }

    private var paymentTitle: String {
        guard let description = payment.paymentDescription,
              !description.isEmpty else {
            return payment.paymentMethod.displayName
        }

        return description
    }
}

private struct ReceiptPreviewSheet: View {
    @Environment(\.dismiss) private var dismiss

    let fileName: String
    let data: Data

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(fileName)
                    .font(.headline)
                    .lineLimit(1)

                Spacer()

                Button("Cerrar") {
                    dismiss()
                }
                .keyboardShortcut(.escape)
            }
            .padding()

            Divider()

            if let image = NSImage(data: data) {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
                    .padding(24)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ContentUnavailableView(
                    "No se pudo abrir el recibo",
                    systemImage: "photo.badge.exclamationmark"
                )
            }
        }
        .frame(minWidth: 520, minHeight: 560)
    }
}

private struct StatusBadge: View {
    let status: PaymentStatus

    var body: some View {
        Text(status.displayName)
            .font(.caption.weight(.medium))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .foregroundStyle(status.foregroundStyle)
            .background(status.backgroundStyle, in: Capsule())
    }
}

private struct VendorFormSheet: View {
    @Environment(\.dismiss) private var dismiss

    let vendor: Vendor?
    @State private var name = ""
    @State private var category: VendorCategory = .venue
    @State private var contractTotal = ""
    @State private var currency = "MXN"
    @State private var contactName = ""
    @State private var contactPhone = ""
    @State private var contactEmail = ""
    @State private var notes = ""

    let onSave: (Vendor) -> Void

    init(vendor: Vendor? = nil, onSave: @escaping (Vendor) -> Void) {
        self.vendor = vendor
        self.onSave = onSave
        _name = State(initialValue: vendor?.name ?? "")
        _category = State(initialValue: vendor?.category ?? .venue)
        _contractTotal = State(
            initialValue: vendor.map {
                NSDecimalNumber(decimal: $0.contractTotal).stringValue
            } ?? ""
        )
        _currency = State(initialValue: vendor?.currency ?? "MXN")
        _contactName = State(initialValue: vendor?.contactName ?? "")
        _contactPhone = State(initialValue: vendor?.contactPhone ?? "")
        _contactEmail = State(initialValue: vendor?.contactEmail ?? "")
        _notes = State(initialValue: vendor?.notes ?? "")
    }

    private var parsedTotal: Decimal? {
        decimalValue(from: contractTotal)
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        parsedTotal != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Proveedor") {
                    TextField("Nombre", text: $name)

                    Picker("Categoría", selection: $category) {
                        ForEach(VendorCategory.allCases) { category in
                            Label(category.displayName, systemImage: category.symbol)
                                .tag(category)
                        }
                    }

                    TextField("Total del contrato", text: $contractTotal)

                    TextField("Moneda", text: $currency)
                }

                Section("Contacto") {
                    TextField("Contacto", text: $contactName)
                    TextField("Teléfono", text: $contactPhone)
                    TextField("Correo", text: $contactEmail)
                    TextField("Notas", text: $notes, axis: .vertical)
                        .lineLimit(3, reservesSpace: true)
                }
            }
            .formStyle(.grouped)
            .navigationTitle(vendor == nil ? "Nuevo proveedor" : "Editar proveedor")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        save()
                    }
                    .disabled(!canSave)
                }
            }
        }
        .frame(width: 460, height: 520)
    }

    private func save() {
        guard let parsedTotal else { return }

        if let vendor {
            vendor.name = trimmed(name)
            vendor.category = category
            vendor.contractTotal = parsedTotal
            vendor.currency = normalizedCurrency(currency)
            vendor.contactName = optionalText(contactName)
            vendor.contactPhone = optionalText(contactPhone)
            vendor.contactEmail = optionalText(contactEmail)
            vendor.notes = optionalText(notes)
            onSave(vendor)
        } else {
            let newVendor = Vendor(
                name: trimmed(name),
                category: category,
                contractTotal: parsedTotal,
                currency: normalizedCurrency(currency),
                contactName: optionalText(contactName),
                contactPhone: optionalText(contactPhone),
                contactEmail: optionalText(contactEmail),
                notes: optionalText(notes)
            )
            onSave(newVendor)
        }

        dismiss()
    }
}

private struct PaymentFormSheet: View {
    @Environment(\.dismiss) private var dismiss

    let vendor: Vendor
    let onSave: (Payment) -> Void

    @State private var amount = ""
    @State private var paidDate = Date()
    @State private var paymentMethod: PaymentMethod = .transfer
    @State private var paymentDescription = ""
    @State private var receipt: ReceiptAttachment?
    @State private var receiptError: String?

    private var parsedAmount: Decimal? {
        decimalValue(from: amount)
    }

    private var canSave: Bool {
        guard let parsedAmount else { return false }
        return parsedAmount > 0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Abono para \(vendor.name)") {
                    TextField("Monto", text: $amount)

                    DatePicker(
                        "Fecha de pago",
                        selection: $paidDate,
                        displayedComponents: .date
                    )

                    Picker("Método", selection: $paymentMethod) {
                        ForEach(PaymentMethod.allCases) { method in
                            Label(method.displayName, systemImage: method.symbol)
                                .tag(method)
                        }
                    }

                    TextField("Descripción", text: $paymentDescription, axis: .vertical)
                        .lineLimit(2, reservesSpace: true)
                }

                Section("Recibo") {
                    if let receipt {
                        HStack(spacing: 12) {
                            if let image = NSImage(data: receipt.data) {
                                Image(nsImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 44, height: 44)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                            }

                            Text(receipt.fileName)
                                .lineLimit(1)

                            Spacer()

                            Button(role: .destructive) {
                                self.receipt = nil
                            } label: {
                                Label("Quitar recibo", systemImage: "xmark.circle")
                            }
                            .labelStyle(.iconOnly)
                            .help("Quitar recibo")
                        }
                    } else {
                        Button(action: chooseReceipt) {
                            Label("Adjuntar imagen", systemImage: "photo.badge.plus")
                        }

                        Text("Opcional: JPG, PNG, HEIC u otra imagen del comprobante.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section {
                    LabeledContent("Saldo actual", value: currencyString(vendor.balance, code: vendor.currency))

                    if let parsedAmount {
                        LabeledContent("Saldo después", value: currencyString(vendor.balance - parsedAmount, code: vendor.currency))
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Registrar abono")
            .alert(
                "No se pudo adjuntar el recibo",
                isPresented: Binding(
                    get: { receiptError != nil },
                    set: { if !$0 { receiptError = nil } }
                )
            ) {
                Button("OK", role: .cancel) {
                    receiptError = nil
                }
            } message: {
                Text(receiptError ?? "Error desconocido.")
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        save()
                    }
                    .disabled(!canSave)
                }
            }
        }
        .frame(width: 430, height: 470)
    }

    private func save() {
        guard let parsedAmount else { return }

        let payment = Payment(
            amount: parsedAmount,
            currency: vendor.currency,
            paidDate: paidDate,
            paymentDescription: optionalText(paymentDescription),
            paymentMethod: paymentMethod,
            receiptFileName: receipt?.fileName,
            receiptData: receipt?.data,
            vendor: vendor
        )

        onSave(payment)
        dismiss()
    }

    @MainActor
    private func chooseReceipt() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.message = "Selecciona una imagen del recibo"

        guard panel.runModal() == .OK, let url = panel.url else { return }

        let maximumSize = 15 * 1024 * 1024
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
              let size = attributes[.size] as? Int,
              size <= maximumSize else {
            receiptError = "La imagen supera el límite de 15 MB."
            return
        }

        do {
            let data = try Data(contentsOf: url)
            guard NSImage(data: data) != nil else {
                receiptError = "El archivo seleccionado no es una imagen válida."
                return
            }
            receipt = ReceiptAttachment(fileName: url.lastPathComponent, data: data)
        } catch {
            receiptError = error.localizedDescription
        }
    }
}

private struct ReceiptAttachment {
    let fileName: String
    let data: Data
}

private extension PaymentMethod {
    var symbol: String {
        switch self {
        case .cash:     return "banknote"
        case .transfer: return "arrow.left.arrow.right"
        case .card:     return "creditcard"
        case .other:    return "ellipsis.circle"
        }
    }
}

private extension PaymentStatus {
    var foregroundStyle: Color {
        switch self {
        case .pending: return .orange
        case .partial: return .blue
        case .paid:    return .green
        }
    }

    var backgroundStyle: Color {
        foregroundStyle.opacity(0.14)
    }
}

private func currencyString(_ amount: Decimal, code: String) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.currencyCode = code
    formatter.maximumFractionDigits = 2
    formatter.minimumFractionDigits = 2

    let number = NSDecimalNumber(decimal: amount)
    return formatter.string(from: number) ?? "\(number) \(code)"
}

private func decimalValue(from text: String) -> Decimal? {
    let cleaned = text
        .replacingOccurrences(of: "$", with: "")
        .replacingOccurrences(of: ",", with: "")
        .trimmingCharacters(in: .whitespacesAndNewlines)

    guard !cleaned.isEmpty,
          let decimal = Decimal(string: cleaned),
          decimal >= 0 else {
        return nil
    }

    return decimal
}

private func normalizedCurrency(_ text: String) -> String {
    let value = trimmed(text).uppercased()
    return value.isEmpty ? "MXN" : value
}

private func optionalText(_ text: String) -> String? {
    let value = trimmed(text)
    return value.isEmpty ? nil : value
}

private func trimmed(_ text: String) -> String {
    text.trimmingCharacters(in: .whitespacesAndNewlines)
}

#Preview {
    VendorsView()
        .modelContainer(
            for: [
                Vendor.self,
                Payment.self,
                Contract.self
            ],
            inMemory: true
        )
}
