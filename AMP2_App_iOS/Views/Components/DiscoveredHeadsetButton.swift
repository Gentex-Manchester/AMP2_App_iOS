//
//  DeviceButton.swift
//  AMP2_App_iOS
//
//  Created by Peter Sargent on 11/24/26.
//

import SwiftUI
import CoreBluetooth

struct DiscoveredHeadsetButton: View {
    let discoveredHeadset: DiscoveredHeadset
    let action: () -> Void
    let debug: Bool

    init(
        discoveredHeadset: DiscoveredHeadset,
        action: @escaping () -> Void,
        debug: Bool = false
    ) {
        self.discoveredHeadset = discoveredHeadset
        self.action = action
        self.debug = debug
    }
    
    var body: some View {
        Button {
            action()
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(discoveredHeadset.name)
                        .appTextStyle(.body)
                    
                    if (debug) {
                        Text(discoveredHeadset.id.uuidString)
                            .font(.system(size: 11, design: .monospaced))
                        if let rssi = discoveredHeadset.rssi {
                            Text("RSSI \(rssi) dBm")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.secondary)
                        }

                        // AccessorySetupKit needs a company ID or service
                        // UUID. No manufacturer data means ASK can't find it.
                        Text(manufacturerText(discoveredHeadset))
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(discoveredHeadset.companyIdentifier == nil ? .red : .green)
                        Text(discoveredHeadset.advertisedServices.isEmpty
                             ? "advertises: (none)"
                             : "advertises: " + discoveredHeadset.advertisedServices
                                 .map(\.uuidString).joined(separator: ", "))
                            .font(.system(size: 11, design: .monospaced))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
            }
            .padding(.vertical, 16)
            .padding(.horizontal)
            .foregroundColor(Color("OnSurface"))
            .frame(maxWidth: .infinity, minHeight: 72)
            .background(Color("Surface"))
            .cornerRadius(16)
        }
    }
    
    /// Advertised company ID (what AccessorySetupKit matches on) and raw bytes.
    private func manufacturerText(_ headset: DiscoveredHeadset) -> String {
        guard let data = headset.manufacturerData, !data.isEmpty else {
            return "mfr data: (none) — ASK cannot match"
        }
        guard let company = headset.companyIdentifier else {
            return "mfr data: \(data.ltcHexString) (too short for a company ID)"
        }
        return String(format: "company 0x%04X — %@", company, data.ltcHexString)
    }
}

#Preview {
    DiscoveredHeadsetButton(
        discoveredHeadset: DiscoveredHeadset(id: UUID(), name: "Test", source: .advertised),
        action: {}
    )
    
    DiscoveredHeadsetButton(
        discoveredHeadset: DiscoveredHeadset(id: UUID(), name: "Test", source: .advertised),
        action: {},
        debug: true
    )
}
