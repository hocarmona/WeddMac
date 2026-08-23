//
//  GuestsView.swift
//  WeddMac
//
//  Created by Hector Carmona on 5/5/26.
//

import SwiftUI
import SwiftData
import AppKit
import PDFKit
internal import UniformTypeIdentifiers

struct GuestsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Guest.name) private var guests: [Guest]

    @State private var searchText = ""
    @State private var rsvpFilter: RSVPStatus? = nil
    @State private var tableFilter: Int? = nil

    @State private var selection: Set<UUID> = []

    @State private var showingAddSheet = false
    @State private var editingGuest: Guest? = nil

    @State private var importPreviewRows: [ParsedGuest] = []
    @State private var showingImportSheet = false

    @State private var errorMessage: String?
    @State private var showingError = false

    private var availableTables: [Int] {
        Array(Set(guests.compactMap(\.tableNumber))).sorted()
    }

    private var filteredGuests: [Guest] {
        guests.filter { g in
            let matchesSearch = searchText.isEmpty ||
                g.name.localizedCaseInsensitiveContains(searchText)
            let matchesRSVP = rsvpFilter == nil || g.rsvpStatus == rsvpFilter
            let matchesTable = tableFilter == nil || g.tableNumber == tableFilter
            return matchesSearch && matchesRSVP && matchesTable
        }
    }

    private var totalSeats: Int {
        guests.reduce(0) { $0 + $1.totalSeats }
    }

    private var confirmedCount: Int { guests.filter { $0.rsvpStatus == .confirmed }.count }
    private var declinedCount: Int { guests.filter { $0.rsvpStatus == .declined }.count }
    private var pendingCount: Int { guests.filter { $0.rsvpStatus == .pending }.count }

    var body: some View {
        VStack(spacing: 0) {
            statsHeader
            Divider()
            if guests.isEmpty {
                emptyState
            } else {
                guestsTable
            }
        }
        .navigationTitle("Invitados")
        .searchable(text: $searchText, prompt: "Buscar invitado")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button("Todos los estados") { rsvpFilter = nil }
                    Divider()
                    ForEach(RSVPStatus.allCases) { status in
                        Button {
                            rsvpFilter = status
                        } label: {
                            Label(status.displayName, systemImage: status.symbol)
                        }
                    }
                } label: {
                    Label(
                        rsvpFilter == nil ? "Filtrar RSVP" : "RSVP: \(rsvpFilter!.displayName)",
                        systemImage: rsvpFilter == nil
                            ? "line.3.horizontal.decrease.circle"
                            : "line.3.horizontal.decrease.circle.fill"
                    )
                }
            }

            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button("Todas las mesas") { tableFilter = nil }
                    if !availableTables.isEmpty {
                        Divider()
                        ForEach(availableTables, id: \.self) { t in
                            Button("Mesa \(t)") { tableFilter = t }
                        }
                    }
                } label: {
                    Label(
                        tableFilter == nil ? "Mesa" : "Mesa \(tableFilter!)",
                        systemImage: tableFilter == nil ? "tablecells" : "tablecells.fill"
                    )
                }
            }

            ToolbarItem(placement: .primaryAction) {
                Button { importGuests() } label: {
                    Label("Importar", systemImage: "square.and.arrow.down")
                }
            }

            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        exportCSV()
                    } label: {
                        Label("Exportar como CSV", systemImage: "tablecells")
                    }
                    Button {
                        exportPDF()
                    } label: {
                        Label("Exportar como PDF", systemImage: "doc.richtext")
                    }
                } label: {
                    Label("Exportar", systemImage: "square.and.arrow.up")
                }
                .disabled(guests.isEmpty)
            }

            ToolbarItem(placement: .primaryAction) {
                Button { showingAddSheet = true } label: {
                    Label("Agregar", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            GuestFormView(guest: nil)
        }
        .sheet(item: $editingGuest) { g in
            GuestFormView(guest: g)
        }
        .sheet(isPresented: $showingImportSheet) {
            GuestImportSheet(rows: importPreviewRows) { confirmed in
                performImport(confirmed)
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    // MARK: - Header

    private var statsHeader: some View {
        HStack(spacing: 24) {
            stat(label: "Total", value: "\(guests.count)", color: .primary)
            stat(label: "Confirmados", value: "\(confirmedCount)", color: .green)
            stat(label: "No asisten", value: "\(declinedCount)", color: .red)
            stat(label: "Pendientes", value: "\(pendingCount)", color: .orange)
            stat(label: "Asientos totales", value: "\(totalSeats)", color: .blue)
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }

    private func stat(label: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(color)
                .monospacedDigit()
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Table

    private var guestsTable: some View {
        Table(filteredGuests, selection: $selection) {
            TableColumn("Nombre") { guest in
                Text(guest.name).fontWeight(.medium)
            }
            TableColumn("Email") { guest in
                Text(guest.email ?? "")
                    .foregroundStyle(.secondary)
            }
            TableColumn("Teléfono") { guest in
                Text(guest.phone ?? "")
                    .foregroundStyle(.secondary)
            }
            TableColumn("Acomp.") { guest in
                Text("\(guest.plusOnes)")
                    .monospacedDigit()
            }
            TableColumn("RSVP") { guest in
                RSVPBadge(status: guest.rsvpStatus)
            }
            TableColumn("Mesa") { guest in
                if let t = guest.tableNumber {
                    Text("\(t)").monospacedDigit()
                } else {
                    Text("—").foregroundStyle(.tertiary)
                }
            }
        }
        .contextMenu(forSelectionType: UUID.self) { ids in
            Button("Marcar como Confirmado") { mark(ids, as: .confirmed) }
            Button("Marcar como No asiste") { mark(ids, as: .declined) }
            Button("Marcar como Pendiente") { mark(ids, as: .pending) }
            Divider()
            if ids.count == 1,
               let id = ids.first,
               let g = guests.first(where: { $0.id == id }) {
                Button("Editar") { editingGuest = g }
            }
            Button("Eliminar", role: .destructive) { delete(ids) }
        } primaryAction: { ids in
            if let id = ids.first, let g = guests.first(where: { $0.id == id }) {
                editingGuest = g
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.3.sequence")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            Text("No hay invitados todavía")
                .font(.title2)
                .foregroundStyle(.secondary)
            HStack {
                Button {
                    showingAddSheet = true
                } label: {
                    Label("Agregar invitado", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)

                Button {
                    importGuests()
                } label: {
                    Label("Importar archivo", systemImage: "square.and.arrow.down")
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Actions

    private func mark(_ ids: Set<UUID>, as status: RSVPStatus) {
        for id in ids {
            if let g = guests.first(where: { $0.id == id }) {
                g.rsvpStatus = status
            }
        }
        try? context.save()
    }

    private func delete(_ ids: Set<UUID>) {
        for id in ids {
            if let g = guests.first(where: { $0.id == id }) {
                context.delete(g)
            }
        }
        try? context.save()
        selection.removeAll()
    }

    // MARK: - Import (CSV / PDF)

    @MainActor
    private func importGuests() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.commaSeparatedText, .plainText, .pdf]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.message = "Selecciona un archivo CSV o PDF con tus invitados"

        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            let parsed: [ParsedGuest]
            if url.pathExtension.lowercased() == "pdf" {
                parsed = try parsePDF(url: url)
            } else {
                let content = try String(contentsOf: url, encoding: .utf8)
                parsed = try GuestCSV.parse(content)
            }
            importPreviewRows = parsed
            showingImportSheet = true
        } catch let CSVError.invalidFormat(message) {
            present(error: message)
        } catch {
            present(error: "No se pudo leer el archivo: \(error.localizedDescription)")
        }
    }

    private func parsePDF(url: URL) throws -> [ParsedGuest] {
        guard let doc = PDFDocument(url: url) else {
            throw CSVError.invalidFormat("No se pudo abrir el PDF.")
        }

        var text = ""
        for i in 0..<doc.pageCount {
            if let page = doc.page(at: i), let pageText = page.string {
                text += pageText + "\n"
            }
        }

        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw CSVError.invalidFormat("El PDF no contiene texto extraíble.")
        }

        // Si la primera línea parece encabezado tipo CSV, reusa el parser
        let firstLine = trimmed.split(whereSeparator: \.isNewline)
            .first.map(String.init) ?? ""
        let looksLikeCSV = firstLine.contains(",") &&
            firstLine.lowercased().contains("name")
        if looksLikeCSV {
            return try GuestCSV.parse(trimmed)
        }

        // Si no, cada línea no vacía se trata como un nombre
        let lines = trimmed.split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        guard !lines.isEmpty else {
            throw CSVError.invalidFormat("No se encontraron nombres en el PDF.")
        }

        return lines.map {
            ParsedGuest(
                name: $0,
                email: nil,
                phone: nil,
                plusOnes: nil,
                rsvpStatus: nil,
                tableNumber: nil,
                dietaryRestrictions: nil,
                notes: nil
            )
        }
    }

    private func performImport(_ rows: [ParsedGuest]) {
        for row in rows {
            let g = Guest(
                name: row.name,
                email: row.email,
                phone: row.phone,
                plusOnes: row.plusOnes ?? 0,
                dietaryRestrictions: row.dietaryRestrictions,
                rsvpStatus: row.rsvpStatus ?? .pending,
                tableNumber: row.tableNumber,
                notes: row.notes
            )
            context.insert(g)
        }
        try? context.save()
        importPreviewRows = []
    }

    // MARK: - CSV Export

    @MainActor
    private func exportCSV() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.commaSeparatedText]
        panel.nameFieldStringValue = "invitados.csv"
        panel.message = "Elige dónde guardar el archivo CSV"

        guard panel.runModal() == .OK, let url = panel.url else { return }

        let csv = GuestCSV.generate(from: guests)
        do {
            try csv.write(to: url, atomically: true, encoding: .utf8)
        } catch {
            present(error: "No se pudo guardar el archivo: \(error.localizedDescription)")
        }
    }

    @MainActor
    private func exportPDF() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.pdf]
        panel.nameFieldStringValue = "invitados.pdf"
        panel.message = "Elige dónde guardar el PDF"

        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            try GuestPDF.generate(guests: guests, to: url)
        } catch {
            present(error: "No se pudo guardar el PDF: \(error.localizedDescription)")
        }
    }

    private func present(error message: String) {
        errorMessage = message
        showingError = true
    }
}

private struct RSVPBadge: View {
    let status: RSVPStatus

    var body: some View {
        Label(status.displayName, systemImage: status.symbol)
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(color.opacity(0.2))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }

    private var color: Color {
        switch status {
        case .pending: return .orange
        case .confirmed: return .green
        case .declined: return .red
        }
    }
}
