//
//  VendorsView.swift
//  WeddMac
//
//  Created by Hector Carmona on 5/5/26.
//

import SwiftUI

struct VendorsView: View {
    var body: some View {
        Text("Vendors")
            .font(.largeTitle)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("Proveedores")
    }
}

#Preview {
    VendorsView()
}
