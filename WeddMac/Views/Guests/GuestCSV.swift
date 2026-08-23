//
//  GuestCSV.swift
//  WeddMac
//
//  Created by Hector Carmona on 5/15/26.
//

import Foundation

struct ParsedGuest: Identifiable {
    let id = UUID()
    var name: String
    var email: String?
    var phone: String?
    var plusOnes: Int?
    var rsvpStatus: RSVPStatus?
    var tableNumber: Int?
    var dietaryRestrictions: String?
    var notes: String?
}

enum CSVError: Error, LocalizedError {
    case invalidFormat(String)

    var errorDescription: String? {
        switch self {
        case .invalidFormat(let m): return m
        }
    }
}

nonisolated enum GuestCSV {
    static func parse(_ content: String) throws -> [ParsedGuest] {
        let rows = splitRows(content)
        guard let headerRow = rows.first else {
            throw CSVError.invalidFormat("El archivo está vacío.")
        }
        let headers = headerRow.map { $0.trimmingCharacters(in: .whitespaces).lowercased() }

        guard let nameIdx = headers.firstIndex(of: "name") else {
            throw CSVError.invalidFormat(
                "Falta la columna obligatoria 'name'. Encabezados encontrados: \(headers.joined(separator: ", "))"
            )
        }

        let emailIdx = headers.firstIndex(of: "email")
        let phoneIdx = headers.firstIndex(of: "phone")
        let plusOnesIdx = headers.firstIndex(of: "plusones")
        let rsvpIdx = headers.firstIndex(of: "rsvpstatus")
        let tableIdx = headers.firstIndex(of: "tablenumber")
        let dietIdx = headers.firstIndex(of: "dietaryrestrictions")
        let notesIdx = headers.firstIndex(of: "notes")

        var result: [ParsedGuest] = []
        for row in rows.dropFirst() {
            guard row.count > nameIdx else { continue }
            let name = row[nameIdx].trimmingCharacters(in: .whitespaces)
            guard !name.isEmpty else { continue }

            let parsed = ParsedGuest(
                name: name,
                email: field(row, emailIdx),
                phone: field(row, phoneIdx),
                plusOnes: field(row, plusOnesIdx).flatMap { Int($0) },
                rsvpStatus: field(row, rsvpIdx).flatMap { RSVPStatus(rawValue: $0.lowercased()) },
                tableNumber: field(row, tableIdx).flatMap { Int($0) },
                dietaryRestrictions: field(row, dietIdx),
                notes: field(row, notesIdx)
            )
            result.append(parsed)
        }

        if result.isEmpty {
            throw CSVError.invalidFormat("No se encontraron filas válidas con nombre.")
        }

        return result
    }

    static func generate(from guests: [Guest]) -> String {
        var lines: [String] = []
        lines.append([
            "name", "email", "phone", "plusOnes",
            "rsvpStatus", "tableNumber", "dietaryRestrictions", "notes"
        ].joined(separator: ","))

        for g in guests {
            let row = [
                g.name,
                g.email ?? "",
                g.phone ?? "",
                String(g.plusOnes),
                g.rsvpStatus.rawValue,
                g.tableNumber.map(String.init) ?? "",
                g.dietaryRestrictions ?? "",
                g.notes ?? ""
            ].map(escape).joined(separator: ",")
            lines.append(row)
        }

        return lines.joined(separator: "\n") + "\n"
    }

    private static func field(_ row: [String], _ index: Int?) -> String? {
        guard let i = index, i < row.count else { return nil }
        let v = row[i].trimmingCharacters(in: .whitespaces)
        return v.isEmpty ? nil : v
    }

    private static func escape(_ s: String) -> String {
        if s.contains(",") || s.contains("\"") || s.contains("\n") || s.contains("\r") {
            let escaped = s.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return s
    }

    private static func splitRows(_ content: String) -> [[String]] {
        var rows: [[String]] = []
        var currentRow: [String] = []
        var currentField = ""
        var inQuotes = false
        let chars = Array(content)
        var i = 0

        while i < chars.count {
            let c = chars[i]
            if inQuotes {
                if c == "\"" {
                    if i + 1 < chars.count && chars[i + 1] == "\"" {
                        currentField.append("\"")
                        i += 2
                        continue
                    } else {
                        inQuotes = false
                    }
                } else {
                    currentField.append(c)
                }
            } else {
                if c == "\"" {
                    inQuotes = true
                } else if c == "," {
                    currentRow.append(currentField)
                    currentField = ""
                } else if c == "\r" || c == "\n" {
                    currentRow.append(currentField)
                    currentField = ""
                    if currentRow.contains(where: { !$0.isEmpty }) {
                        rows.append(currentRow)
                    }
                    currentRow = []
                    if c == "\r" && i + 1 < chars.count && chars[i + 1] == "\n" {
                        i += 2
                        continue
                    }
                } else {
                    currentField.append(c)
                }
            }
            i += 1
        }

        if !currentField.isEmpty || !currentRow.isEmpty {
            currentRow.append(currentField)
            if currentRow.contains(where: { !$0.isEmpty }) {
                rows.append(currentRow)
            }
        }

        return rows
    }
}
