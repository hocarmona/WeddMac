//
//  BudgetView.swift
//  WeddMac
//
//  Created by Hector Carmona on 5/5/26.
//

import SwiftUI
import SwiftData
import Charts

struct BudgetView: View {
    @Environment(\.modelContext) private var context
    @Query private var weddings: [Wedding]
    @Query private var vendors: [Vendor]
    @Query(sort: \Payment.paidDate, order: .reverse) private var payments: [Payment]
    
    @State private var showingWeddingEditor = false
    
    private var wedding: Wedding {
        weddings.first ?? Wedding.fetchOrCreate(in: context)
    }
    
    private var totalBudget: Decimal { wedding.totalBudget }
    
    private var totalContracted: Decimal {
        vendors.reduce(Decimal.zero) { $0 + $1.contractTotal }
    }
    
    private var totalPaid: Decimal {
        payments
            .reduce(Decimal.zero) { $0 + $1.amount }
    }
    
    private var totalPending: Decimal { totalContracted - totalPaid }
    private var remainingBudget: Decimal { totalBudget - totalContracted }
    
    private var currency: String { wedding.defaultCurrency }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                kpiSection
                
                if !vendors.isEmpty {
                    categoryChartSection
                    vendorBarsSection
                }
                
                upcomingPaymentsSection
                recentActivitySection
            }
            .padding(24)
        }
        .navigationTitle("Presupuesto")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingWeddingEditor = true
                } label: {
                    Label("Editar boda", systemImage: "gearshape")
                }
            }
        }
        .sheet(isPresented: $showingWeddingEditor) {
            WeddingEditorView(wedding: wedding)
        }
    }
    
    // MARK: - KPI Cards
    
    private var kpiSection: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 220), spacing: 16)],
            spacing: 16
        ) {
            KPICard(
                title: "Presupuesto total",
                amount: totalBudget,
                currency: currency,
                icon: "dollarsign.circle.fill",
                tint: .blue,
                emphasis: true
            )
            KPICard(
                title: "Contratado",
                amount: totalContracted,
                currency: currency,
                icon: "doc.text.fill",
                tint: .indigo
            )
            KPICard(
                title: "Pagado",
                amount: totalPaid,
                currency: currency,
                icon: "checkmark.circle.fill",
                tint: .green
            )
            KPICard(
                title: "Pendiente",
                amount: totalPending,
                currency: currency,
                icon: "clock.fill",
                tint: pendingTint
            )
            
            if totalBudget > 0 {
                RemainingBudgetCard(
                    remaining: remainingBudget,
                    currency: currency
                )
                .gridCellColumns(2)
            }
        }
    }
    
    private var pendingTint: Color {
        if totalPending <= 0 { return .green }
        let ratio = NSDecimalNumber(decimal: totalPending).doubleValue
              / max(NSDecimalNumber(decimal: totalContracted).doubleValue, 1)
        if ratio > 0.5 { return .red }
        if ratio > 0.2 { return .orange }
        return .yellow
    }
    
    // MARK: - Category Pie Chart
    
    private var categoryChartSection: some View {
        SectionCard(title: "Distribución por categoría") {
            HStack(alignment: .center, spacing: 24) {
                Chart(categoryTotals, id: \.category) { item in
                    SectorMark(
                        angle: .value("Total", NSDecimalNumber(decimal: item.total).doubleValue),
                        innerRadius: .ratio(0.55),
                        angularInset: 1.5
                    )
                    .foregroundStyle(item.category.color)
                    .cornerRadius(4)
                }
                .frame(width: 240, height: 240)
                
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(categoryTotals, id: \.category) { item in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(item.category.color)
                                .frame(width: 10, height: 10)
                            Text(item.category.label)
                                .font(.callout)
                            Spacer()
                            Text(formatMoney(item.total, currency: currency))
                                .font(.callout.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
    
    private var categoryTotals: [(category: VendorCategory, total: Decimal)] {
        Dictionary(grouping: vendors, by: \.category)
            .map { (category: $0.key, total: $0.value.reduce(Decimal.zero) { $0 + $1.contractTotal }) }
            .filter { $0.total > 0 }
            .sorted { $0.total > $1.total }
    }
    
    // MARK: - Vendor Bars
    
    private var vendorBarsSection: some View {
        SectionCard(title: "Pago por proveedor") {
            Chart(sortedVendors, id: \.id) { vendor in
                BarMark(
                    x: .value("Total", NSDecimalNumber(decimal: vendor.contractTotal).doubleValue),
                    y: .value("Proveedor", vendor.name)
                )
                .foregroundStyle(vendor.category.color.opacity(0.25))
                .cornerRadius(4)
                
                BarMark(
                    x: .value("Pagado", NSDecimalNumber(decimal: vendor.totalPaid).doubleValue),
                    y: .value("Proveedor", vendor.name)
                )
                .foregroundStyle(vendor.category.color)
                .cornerRadius(4)
            }
            .chartXAxis {
                AxisMarks(format: .currency(code: currency).precision(.fractionLength(0)))
            }
            .frame(height: CGFloat(max(sortedVendors.count, 1)) * 36 + 40)
        }
    }
    
    private var sortedVendors: [Vendor] {
        vendors.sorted { $0.balance > $1.balance }
    }
    
    // MARK: - Upcoming Payments
    
    private var upcomingPaymentsSection: some View {
        SectionCard(title: "Próximos pagos (30 días)") {
            if upcomingPayments.isEmpty {
                Text("No hay pagos próximos")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 12)
            } else {
                VStack(spacing: 0) {
                    ForEach(upcomingPayments) { payment in
                        PaymentRow(payment: payment, currency: currency, mode: .upcoming)
                        if payment.id != upcomingPayments.last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
    }
    
    private var upcomingPayments: [Payment] {
        let now = Date()
        let in30 = Calendar.current.date(byAdding: .day, value: 30, to: now) ?? now
        return payments
            .compactMap { p -> (Payment, Date)? in
                guard let due = p.dueDate, due >= now, due <= in30 else { return nil }
                return (p, due)
            }
            .sorted { $0.1 < $1.1 }
            .map { $0.0 }
    }
    
    // MARK: - Recent Activity
    
    private var recentActivitySection: some View {
        SectionCard(title: "Actividad reciente") {
            if recentPayments.isEmpty {
                Text("Sin pagos registrados")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 12)
            } else {
                VStack(spacing: 0) {
                    ForEach(recentPayments) { payment in
                        PaymentRow(payment: payment, currency: currency, mode: .recent)
                        if payment.id != recentPayments.last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
    }
    
    private var recentPayments: [Payment] {
        payments
            .prefix(5)
            .map { $0 }
    }
}

// MARK: - KPI Card

private struct KPICard: View {
    let title: String
    let amount: Decimal
    let currency: String
    let icon: String
    let tint: Color
    var emphasis: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundStyle(tint)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(formatMoney(amount, currency: currency))
                .font(emphasis ? .title.bold() : .title2.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(emphasis ? tint : .primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.secondary.opacity(0.15))
        )
    }
}

// MARK: - Remaining Budget Card

private struct RemainingBudgetCard: View {
    let remaining: Decimal
    let currency: String
    
    private var isNegative: Bool { remaining < 0 }
    
    var body: some View {
        HStack {
            Image(systemName: isNegative ? "exclamationmark.triangle.fill" : "leaf.fill")
                .foregroundStyle(isNegative ? .red : .green)
            VStack(alignment: .leading, spacing: 2) {
                Text(isNegative ? "Te excediste del presupuesto" : "Disponible en el presupuesto")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(formatMoney(remaining, currency: currency))
                    .font(.title3.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(isNegative ? .red : .primary)
            }
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill((isNegative ? Color.red : Color.green).opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder((isNegative ? Color.red : Color.green).opacity(0.3))
        )
    }
}

// MARK: - Section Card

private struct SectionCard<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            content
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.secondary.opacity(0.15))
        )
    }
}

// MARK: - Payment Row

private struct PaymentRow: View {
    enum Mode { case upcoming, recent }
    let payment: Payment
    let currency: String
    let mode: Mode
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(payment.vendor?.category.color ?? .gray)
                .frame(width: 8, height: 8)
            VStack(alignment: .leading, spacing: 2) {
                Text(payment.vendor?.name ?? "Sin proveedor")
                    .font(.callout)
                if let desc = payment.paymentDescription, !desc.isEmpty {
                    Text(desc)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(formatMoney(payment.amount, currency: payment.currency))
                    .font(.callout.monospacedDigit())
                if let date = mode == .upcoming ? payment.dueDate : payment.paidDate {
                    Text(date.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 10)
    }
}

// MARK: - Wedding Editor

private struct WeddingEditorView: View {
    @Bindable var wedding: Wedding
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Form {
            Section("Boda") {
                TextField("Nombre", text: $wedding.name)
                DatePicker("Fecha", selection: $wedding.date, displayedComponents: .date)
            }
            Section("Presupuesto") {
                TextField(
                    "Presupuesto total",
                    value: $wedding.totalBudget,
                    format: .number
                )
                TextField("Moneda (ISO)", text: $wedding.defaultCurrency)
            }
        }
        .formStyle(.grouped)
        .frame(width: 420, height: 320)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cerrar") { dismiss() }
            }
        }
    }
}

// MARK: - Money Formatter

func formatMoney(_ amount: Decimal, currency: String) -> String {
    amount.formatted(.currency(code: currency).precision(.fractionLength(0)))
}
