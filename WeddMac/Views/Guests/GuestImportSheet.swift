//
//  GuestImportSheet.swift
//  WeddMac
//
//  Created by Hector Carmona on 5/15/26.
//

import SwiftUI

struct GuestImportSheet: View {
    @Environment(\.dismiss) private var dismiss

    let rows: [ParsedGuest]
    let onConfirm: ([ParsedGuest]) -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                summaryHeader
                Divider()
                Table(rows) {
                    TableColumn("Nombre") { Text($0.name) }
                    TableColumn("Email") { Text($0.email ?? "") }
                    TableColumn("Teléfono") { Text($0.phone ?? "") }
                    TableColumn("Acomp.") { row in
                        Text(row.plusOnes.map(String.init) ?? "0")
                            .monospacedDigit()
                    }
                    TableColumn("RSVP") { row in
                        Text((row.rsvpStatus ?? .pending).displayName)
                    }
                    TableColumn("Mesa") { row in
                        Text(row.tableNumber.map(String.init) ?? "—")
                            .monospacedDigit()
                    }
                }
            }
            .navigationTitle("Previsualizar importación")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Importar \(rows.count)") {
                        onConfirm(rows)
                        dismiss()
                    }
                    .disabled(rows.isEmpty)
                }
            }
        }
        .frame(minWidth: 760, minHeight: 480)
    }

    private var summaryHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(rows.count) invitados detectados")
                    .font(.headline)
                Text("Revisa los datos antes de confirmar la importación.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding()
    }
}
