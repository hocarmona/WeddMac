//
//  ContractRowView.swift
//  WeddMac
//

import SwiftUI

struct ContractRowView: View {
    let contract: Contract

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "doc.fill")
                .font(.title2)
                .foregroundStyle(.red)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(contract.fileName)
                    .font(.body)
                    .lineLimit(1)
                    .truncationMode(.middle)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(sizeLabel)
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }

    private var sizeLabel: String {
        let kb = Double(contract.fileData.count) / 1024.0
        if kb >= 1024 {
            return String(format: "%.1f MB", kb / 1024)
        }
        return String(format: "%.0f KB", kb)
    }

    private var subtitle: String {
        contract.uploadedDate.formatted(date: .abbreviated, time: .omitted)
    }
}
