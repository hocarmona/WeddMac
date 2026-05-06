//
//  Contract.swift
//  WeddMac
//
//  Created by Hector Carmona on 5/4/26.
//

import Foundation
import SwiftData

@Model
final class Contract {
    var id: UUID
    var fileName: String

    @Attribute(.externalStorage)
    var fileData: Data

    var uploadedDate: Date
    var notes: String?

    var vendor: Vendor?

    init(
        fileName: String,
        fileData: Data,
        uploadedDate: Date = Date(),
        notes: String? = nil,
        vendor: Vendor? = nil
    ) {
        self.id = UUID()
        self.fileName = fileName
        self.fileData = fileData
        self.uploadedDate = uploadedDate
        self.notes = notes
        self.vendor = vendor
    }
}
