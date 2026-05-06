//
//  VendorDetailView.swift
//  WeddMac
//
//  Created by Hector Carmona on 5/5/26.
//

import SwiftUI
import SwiftData

struct VendorDetailView: View {
    @Bindable var vendor: Vendor
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                Divider()
                contactSection
                Divider()
                financialSection
                Divider()
                paymentsSection
                Divider()
                contractsSection
            }
            .padding(24)
        }
        .navigationTitle(vendor.name)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingEditSheet = true
                } label: {
                    Label("Editar", systemImage: "pencil")
                }
            }
            ToolbarItem(placement: .destructiveAction) {
                Button(role: .destructive) {
                    showingDeleteAlert = true
                } label: {
                    Label("Eliminar", systemImage: "trash")
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            VendorFormView(vendor: vendor)
        }
        .alert("¿Eliminar proveedor?", isPresented: $showingDeleteAlert) {
            Button("Cancelar", role: .cancel) { }
            Button("Eliminar", role: .destructive) { delete() }
        } message: {
            Text("Esta acción no se puede deshacer. Se eliminarán también sus pagos y contratos.")
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: vendor.category.sfSymbol)
                .font(.system(size: 48))
                .foregroundStyle(.tint)
                .frame(width: 80, height: 80)
                .background(Color.accentColor.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 6) {
                Text(vendor.name)
                    .font(.largeTitle.bold())
                Text(vendor.category.displayName)
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("Saldo")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(vendor.balance.formattedAsCurrency(code: vendor.currency))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(vendor.balance == 0 ? .green : .primary)
            }
        }
    }

    private var contactSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Contacto")

            if vendor.contactName == nil && vendor.contactPhone == nil && vendor.contactEmail == nil {
                Text("Sin información de contacto")
                    .foregroundStyle(.secondary)
            } else {
                if let name = vendor.contactName {
                    infoRow(icon: "person", label: "Nombre", value: name)
                }
                if let phone = vendor.contactPhone {
                    infoRow(icon: "phone", label: "Teléfono", value: phone)
                }
                if let email = vendor.contactEmail {
                    infoRow(icon: "envelope", label: "Email", value: email)
                }
            }
        }
    }

    private var financialSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Resumen financiero")

            let total = vendor.contractTotal
            let paid = vendor.totalPaid
            let balance = vendor.balance
            let percent: Double = {
                guard total > 0 else { return 0 }
                return NSDecimalNumber(decimal: paid).doubleValue /
                       NSDecimalNumber(decimal: total).doubleValue
            }()

            HStack(spacing: 16) {
                financialBox(title: "Contrato", value: total.formattedAsCurrency(code: vendor.currency), color: .blue)
                financialBox(title: "Pagado", value: paid.formattedAsCurrency(code: vendor.currency), color: .green)
                financialBox(title: "Saldo", value: balance.formattedAsCurrency(code: vendor.currency), color: balance == 0 ? .green : .orange)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Progreso")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(percent, format: .percent.precision(.fractionLength(0)))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                ProgressView(value: min(percent, 1.0))
                    .tint(vendor.paymentStatus.color)
            }
        }
    }

    private var paymentsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Pagos")
            // TODO: lista real de payments
            Text("No payments yet")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 12)
        }
    }

    private var contractsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Documentos")
            // TODO: lista real de contracts/PDFs
            Text("No documents yet")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 12)
        }
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
    }

    private func infoRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .frame(width: 20)
                .foregroundStyle(.secondary)
            Text(label)
                .foregroundStyle(.secondary)
                .frame(width: 80, alignment: .leading)
            Text(value)
                .textSelection(.enabled)
            Spacer()
        }
    }

    private func financialBox(title: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.bold())
                .monospacedDigit()
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func delete() {
        context.delete(vendor)
        try? context.save()
    }
}
