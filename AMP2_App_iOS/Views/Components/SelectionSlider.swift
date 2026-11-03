//
//  SelectionSlider.swift
//  AMP2_App_iOS
//
//  Created by Peter Sargent on 11/3/26.
//

import SwiftUI

struct SelectionSlider: View {

    let level: Double
    let range: ClosedRange<Double>

    @State private var draftLevel: Double?

    let onSelection: (Double) -> Void
    let label: (Double) -> String
    let description: String?
    let lowLabel: String
    let highLabel: String

    init(
        level: Double,
        range: ClosedRange<Double>,
        onSelection: @escaping (Double) -> Void,
        label: @escaping (Double) -> String,
        description: String? = nil,
        lowLabel: String = "Low",
        highLabel: String = "High"
    ) {
        self.level = level
        self.range = range
        self.onSelection = onSelection
        self.label = label
        self.description = description
        self.lowLabel = lowLabel
        self.highLabel = highLabel
    }

    var body: some View {
        VStack(spacing: 10) {

            if let description = description {
                AppText(description, style: .body)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 16)
            }

            VStack(spacing: 12) {

                Slider(
                    value: Binding(
                        get: { draftLevel ?? level },
                        set: { draftLevel = $0 }
                    ),
                    in: range,
                    step: 1,
                    onEditingChanged: { editing in

                        guard !editing else { return }

                        if let draftLevel {
                            onSelection(draftLevel)
                        }

                        self.draftLevel = nil
                    }
                )
                .tint(.accent)
                .padding(.horizontal, 16)

                HStack {
                    AppText(lowLabel, style: .subbody)
                        .foregroundColor(.secondary)

                    Spacer()

                    AppText(label(draftLevel ?? level), style: .body)

                    Spacer()

                    AppText(highLabel, style: .subbody)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 16)
            }
        }
    }
}


#Preview {
    @Previewable @State var draftLevel: Double?
    var level: Double {
        draftLevel ?? Double(0)
    }
    
    SelectionSlider(
        level: level,
        range: 0...10,
        onSelection: { selection in
            print("Selected \(selection)")
        },
        label: { selection in
            "\(selection)"
        },
        description: "Test description"
    )
}
