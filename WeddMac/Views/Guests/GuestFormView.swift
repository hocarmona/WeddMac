//
//  GuestFormView.swift
//  WeddMac
//
//  Created by Hector Carmona on 5/15/26.
//

import SwiftUI
import SwiftData

struct GuestFormView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let guest: Guest?

    @State private var name: String = ""
    @State private var email: String = ""
    @State private var phone: String = ""
    @State private var plusOnes: Int = 0
    @State private var dietaryRestrictions: String = ""
    @State private var rsvpStatus: RSVPStatus = .pending
    @State private var hasTable: Bool = false
    @State private var tableNumber: Int = 1
    @State private var notes: String = ""

    private var isEditing: Bool { guest != nil }
    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Información básica") {
                    TextField("Nombre", text: $name)
                    TextField("Email", text: $email)
                    TextField("Teléfono", text: $phone)
                    Stepper(value: $plusOnes, in: 0...20) {
                        Text("Acompañantes: \(plusOnes)")
                    }
                }

                Section("RSVP") {
                    Picker("Estado", selection: $rsvpStatus) {
                        ForEach(RSVPStatus.allCases) { status in
                            Label(status.displayName, systemImage: status.symbol).tag(status)
                        }
                    }
                    Toggle("Asignar mesa", isOn: $hasTable)
                    if hasTable {
                        Stepper(value: $tableNumber, in: 1...100) {
                            Text("Mesa \(tableNumber)")
                        }
                    }
                }

                Section("Detalles") {
                    TextField("Restricciones alimentarias", text: $dietaryRestrictions)
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                }
            }
            .formStyle(.grouped)
            .navigationTitle(isEditing ? "Editar invitado" : "Nuevo invitado")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") { save() }
                        .disabled(!isValid)
                }
            }
            .onAppear(perform: loadGuest)
        }
        .frame(minWidth: 460, minHeight: 560)
    }

    private func loadGuest() {
        guard let g = guest else { return }
        name = g.name
        email = g.email ?? ""
        phone = g.phone ?? ""
        plusOnes = g.plusOnes
        dietaryRestrictions = g.dietaryRestrictions ?? ""
        rsvpStatus = g.rsvpStatus
        if let t = g.tableNumber {
            hasTable = true
            tableNumber = t
        }
        notes = g.notes ?? ""
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        if let g = guest {
            g.name = trimmedName
            g.email = email.isEmpty ? nil : email
            g.phone = phone.isEmpty ? nil : phone
            g.plusOnes = plusOnes
            g.dietaryRestrictions = dietaryRestrictions.isEmpty ? nil : dietaryRestrictions
            g.rsvpStatus = rsvpStatus
            g.tableNumber = hasTable ? tableNumber : nil
            g.notes = notes.isEmpty ? nil : notes
        } else {
            let newGuest = Guest(
                name: trimmedName,
                email: email.isEmpty ? nil : email,
                phone: phone.isEmpty ? nil : phone,
                plusOnes: plusOnes,
                dietaryRestrictions: dietaryRestrictions.isEmpty ? nil : dietaryRestrictions,
                rsvpStatus: rsvpStatus,
                tableNumber: hasTable ? tableNumber : nil,
                notes: notes.isEmpty ? nil : notes
            )
            context.insert(newGuest)
        }

        try? context.save()
        dismiss()
    }
}
