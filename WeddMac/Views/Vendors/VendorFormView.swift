//
//  VendorFormView.swift
//  WeddMac
//
//  Created by Hector Carmona on 5/5/26.
//

import SwiftUI
import SwiftData

struct VendorFormView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let vendor: Vendor?

    @State private var name: String = ""
    @State private var category: VendorCategory = .other
    @State private var contractTotal: Decimal = 0
    @State private var currency: String = "MXN"

    @State private var contactName: String = ""
    @State private var contactPhone: String = ""
    @State private var contactEmail: String = ""

    @State private var hasContractDate: Bool = false
    @State private var contractDate: Date = .now
    @State private var hasServiceDate: Bool = false
    @State private var serviceDate: Date = .now

    @State private var notes: String = ""

    private var isEditing: Bool { vendor != nil }
    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && contractTotal > 0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Información básica") {
                    TextField("Nombre", text: $name)

                    Picker("Categoría", selection: $category) {
                        ForEach(VendorCategory.allCases, id: \.self) { cat in
                            Label(cat.displayName, systemImage: cat.sfSymbol)
                                .tag(cat)
                        }
                    }

                    TextField("Total del contrato", value: $contractTotal, format: .number)

                    TextField("Moneda (ISO)", text: $currency)
                        .textCase(.uppercase)
                }

                Section("Contacto") {
                    TextField("Nombre de contacto", text: $contactName)
                    TextField("Teléfono", text: $contactPhone)
                    TextField("Email", text: $contactEmail)
                }

                Section("Fechas") {
                    Toggle("Fecha de contrato", isOn: $hasContractDate)
                    if hasContractDate {
                        DatePicker("Contrato firmado", selection: $contractDate, displayedComponents: .date)
                    }

                    Toggle("Fecha de servicio", isOn: $hasServiceDate)
                    if hasServiceDate {
                        DatePicker("Servicio", selection: $serviceDate, displayedComponents: .date)
                    }
                }

                Section("Notas") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                }
            }
            .formStyle(.grouped)
            .navigationTitle(isEditing ? "Editar proveedor" : "Nuevo proveedor")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") { save() }
                        .disabled(!isValid)
                }
            }
            .onAppear(perform: loadVendor)
        }
        .frame(minWidth: 500, minHeight: 600)
    }

    private func loadVendor() {
        guard let vendor else { return }
        name = vendor.name
        category = vendor.category
        contractTotal = vendor.contractTotal
        currency = vendor.currency
        contactName = vendor.contactName ?? ""
        contactPhone = vendor.contactPhone ?? ""
        contactEmail = vendor.contactEmail ?? ""
        if let d = vendor.contractDate {
            hasContractDate = true
            contractDate = d
        }
        if let d = vendor.serviceDate {
            hasServiceDate = true
            serviceDate = d
        }
        notes = vendor.notes ?? ""
    }

    private func save() {
        let trimmedCurrency = currency.trimmingCharacters(in: .whitespaces).uppercased()
        let finalCurrency = trimmedCurrency.isEmpty ? "MXN" : trimmedCurrency

        if let vendor {
            vendor.name = name
            vendor.category = category
            vendor.contractTotal = contractTotal
            vendor.currency = finalCurrency
            vendor.contactName = contactName.isEmpty ? nil : contactName
            vendor.contactPhone = contactPhone.isEmpty ? nil : contactPhone
            vendor.contactEmail = contactEmail.isEmpty ? nil : contactEmail
            vendor.contractDate = hasContractDate ? contractDate : nil
            vendor.serviceDate = hasServiceDate ? serviceDate : nil
            vendor.notes = notes.isEmpty ? nil : notes
        } else {
            let newVendor = Vendor(
                name: name,
                category: category,
                contractTotal: contractTotal,
                currency: finalCurrency,
                contactName: contactName.isEmpty ? nil : contactName,
                contactPhone: contactPhone.isEmpty ? nil : contactPhone,
                contactEmail: contactEmail.isEmpty ? nil : contactEmail,
                notes: notes.isEmpty ? nil : notes,
                contractDate: hasContractDate ? contractDate : nil,
                serviceDate: hasServiceDate ? serviceDate : nil
            )
            context.insert(newVendor)
        }

        try? context.save()
        dismiss()
    }
}
