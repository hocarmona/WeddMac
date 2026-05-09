//
//  PDFViewerSheet.swift
//  WeddMac
//

import SwiftUI
import PDFKit
import AppKit
internal import UniformTypeIdentifiers

struct PDFViewerSheet: View {
    let contract: Contract
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()
            PDFKitView(data: contract.fileData)
                .frame(minWidth: 600, minHeight: 700)
        }
        .frame(minWidth: 620, minHeight: 740)
    }

    private var toolbar: some View {
        HStack(spacing: 12) {
            Text(contract.fileName)
                .font(.headline)
                .lineLimit(1)
                .truncationMode(.middle)

            Spacer()

            Button {
                exportPDF()
            } label: {
                Label("Exportar", systemImage: "square.and.arrow.down")
            }
            .help("Guardar como…")

            Button("Cerrar") {
                dismiss()
            }
            .keyboardShortcut(.escape)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.bar)
    }

    @MainActor
    private func exportPDF() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.pdf]
        panel.nameFieldStringValue = contract.fileName
        panel.canCreateDirectories = true

        if panel.runModal() == .OK, let url = panel.url {
            try? contract.fileData.write(to: url)
        }
    }
}

// MARK: - NSViewRepresentable wrapper

struct PDFKitView: NSViewRepresentable {
    let data: Data

    func makeNSView(context: Context) -> PDFView {
        let view = PDFView()
        view.autoScales = true
        view.displayMode = .singlePageContinuous
        view.displayDirection = .vertical
        return view
    }

    func updateNSView(_ nsView: PDFView, context: Context) {
        nsView.document = PDFDocument(data: data)
    }
}
