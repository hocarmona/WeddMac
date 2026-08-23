//
//  GuestPDF.swift
//  WeddMac
//
//  Created by Hector Carmona on 5/15/26.
//

import AppKit
import CoreText

enum GuestPDF {
    static func generate(guests: [Guest], to url: URL) throws {
        let pageSize = CGSize(width: 612, height: 792) // US Letter
        var mediaBox = CGRect(origin: .zero, size: pageSize)

        guard let context = CGContext(url as CFURL, mediaBox: &mediaBox, nil) else {
            throw NSError(
                domain: "GuestPDF",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "No se pudo crear el archivo PDF."]
            )
        }

        let margin: CGFloat = 40
        let columns: [(title: String, width: CGFloat)] = [
            ("Nombre", 170),
            ("Email", 170),
            ("Teléfono", 90),
            ("Acomp.", 45),
            ("RSVP", 65),
            ("Mesa", 40)
        ]

        let rowHeight: CGFloat = 18
        let titleSpace: CGFloat = 60
        let columnHeaderSpace: CGFloat = 24
        let bottomMargin: CGFloat = 40
        let usableHeight = pageSize.height - titleSpace - columnHeaderSpace - bottomMargin
        let rowsPerPage = max(1, Int(usableHeight / rowHeight))
        let totalPages = guests.isEmpty
            ? 1
            : Int(ceil(Double(guests.count) / Double(rowsPerPage)))

        for page in 0..<totalPages {
            context.beginPDFPage(nil)

            let startIdx = page * rowsPerPage
            let endIdx = min(startIdx + rowsPerPage, guests.count)
            let pageGuests = guests.isEmpty ? [] : Array(guests[startIdx..<endIdx])

            // Título
            draw(
                "Lista de Invitados",
                x: margin,
                y: pageSize.height - margin - 18,
                font: NSFont.boldSystemFont(ofSize: 18),
                color: .black,
                in: context
            )

            let dateStr = Date().formatted(date: .long, time: .omitted)
            draw(
                "\(guests.count) invitados · Página \(page + 1) de \(totalPages) · \(dateStr)",
                x: margin,
                y: pageSize.height - margin - 36,
                font: NSFont.systemFont(ofSize: 10),
                color: NSColor.darkGray,
                in: context
            )

            // Encabezados de columna
            var x = margin
            let headerY = pageSize.height - margin - titleSpace
            for col in columns {
                draw(
                    col.title,
                    x: x + 4,
                    y: headerY,
                    font: NSFont.boldSystemFont(ofSize: 10),
                    color: .black,
                    in: context
                )
                x += col.width
            }

            context.setStrokeColor(NSColor.lightGray.cgColor)
            context.setLineWidth(0.5)
            context.move(to: CGPoint(x: margin, y: headerY - 6))
            context.addLine(to: CGPoint(x: pageSize.width - margin, y: headerY - 6))
            context.strokePath()

            // Filas
            var y = headerY - 6 - rowHeight
            for guest in pageGuests {
                x = margin
                let cells = [
                    guest.name,
                    guest.email ?? "",
                    guest.phone ?? "",
                    "\(guest.plusOnes)",
                    guest.rsvpStatus.displayName,
                    guest.tableNumber.map(String.init) ?? "—"
                ]
                for (i, text) in cells.enumerated() {
                    draw(
                        text,
                        x: x + 4,
                        y: y + 4,
                        font: NSFont.systemFont(ofSize: 9),
                        color: .black,
                        in: context,
                        maxWidth: columns[i].width - 8
                    )
                    x += columns[i].width
                }
                y -= rowHeight
            }

            context.endPDFPage()
        }

        context.closePDF()
    }

    private static func draw(
        _ text: String,
        x: CGFloat,
        y: CGFloat,
        font: NSFont,
        color: NSColor,
        in context: CGContext,
        maxWidth: CGFloat? = nil
    ) {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color
        ]
        let attrString = NSAttributedString(string: text, attributes: attrs)
        let line = CTLineCreateWithAttributedString(attrString)

        let finalLine: CTLine
        if let maxWidth {
            let token = CTLineCreateWithAttributedString(
                NSAttributedString(string: "…", attributes: attrs)
            )
            finalLine = CTLineCreateTruncatedLine(line, Double(maxWidth), .end, token) ?? line
        } else {
            finalLine = line
        }

        context.textPosition = CGPoint(x: x, y: y)
        CTLineDraw(finalLine, context)
    }
}
