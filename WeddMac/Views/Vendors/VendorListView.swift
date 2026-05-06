//
//  VendorListView.swift
//  WeddMac
//
//  Created by Hector Carmona on 5/5/26.
//

import SwiftUI
import SwiftData

struct VendorListView: View {
    @Query(sort: \Vendor.name) private var vendors: [Vendor]
    @Environment(\.modelContext) private var context

    @Binding var selectedVendor: Vendor?

    @State private var searchText = ""
    @State private var categoryFilter: VendorCategory? = nil
    @State private var showingAddSheet = false

    private var filteredVendors: [Vendor] {
        vendors.filter { vendor in
            let matchesSearch = searchText.isEmpty ||
                vendor.name.localizedCaseInsensitiveContains(searchText)
            let matchesCategory = categoryFilter == nil || vendor.category == categoryFilter
            return matchesSearch && matchesCategory
        }
    }

    var body: some View {
        Group {
            if vendors.isEmpty {
                emptyState
            } else {
                vendorList
            }
        }
        .navigationTitle("Proveedores")
        .searchable(text: $searchText, prompt: "Buscar proveedor")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button("Todas las categorías") { categoryFilter = nil }
                    Divider()
                    ForEach(VendorCategory.allCases, id: \.self) { cat in
                        Button {
                            categoryFilter = cat
                        } label: {
                            Label(cat.displayName, systemImage: cat.sfSymbol)
                        }
                    }
                } label: {
                    Label("Filtrar", systemImage: "line.3.horizontal.decrease.circle")
                }
            }

            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddSheet = true
                } label: {
                    Label("Agregar", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            VendorFormView(vendor: nil)
        }
    }

    private var vendorList: some View {
        List(selection: $selectedVendor) {
            ForEach(filteredVendors) { vendor in
                VendorRow(vendor: vendor)
                    .tag(vendor)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.2.slash")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            Text("No hay proveedores todavía")
                .font(.title2)
                .foregroundStyle(.secondary)
            Button {
                showingAddSheet = true
            } label: {
                Label("Agregar el primero", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct VendorRow: View {
    let vendor: Vendor

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: vendor.category.sfSymbol)
                .font(.title2)
                .foregroundStyle(.tint)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(vendor.name)
                    .font(.headline)
                Text(vendor.category.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(vendor.contractTotal.formattedAsCurrency(code: vendor.currency))
                    .font(.subheadline)
                    .monospacedDigit()
                StatusBadge(status: vendor.paymentStatus)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct StatusBadge: View {
    let status: PaymentStatus

    var body: some View {
        Text(status.displayName)
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(status.color.opacity(0.2))
            .foregroundStyle(status.color)
            .clipShape(Capsule())
    }
}
