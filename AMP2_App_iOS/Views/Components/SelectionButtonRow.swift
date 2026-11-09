//
//  SelectionButtonRow.swift
//  AMP2_App_iOS
//
//  Created by Peter Sargent on 11/3/26.
//

import SwiftUI

struct SelectionButtonRow<Option: Hashable>: View {
    
    let options: [Option]
    @Binding var selection: Option
    let onSelection: (Option) -> Void
    let label: (Option) -> String
    let description: String?
    
    init(
        options: [Option],
        selection: Binding<Option>,
        @ViewBuilder onSelection: @escaping (Option) -> Void,
        @ViewBuilder label: @escaping (Option) -> String,
        description: String? = nil
    ) {
        self.options = options
        self._selection = selection
        self.onSelection = onSelection
        self.label = label
        self.description = description
    }
    
    private let columns = 2
    
    var body: some View {
        VStack(spacing: 12) {
            if let description = description {
                AppText(description, style: .body)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 16)
                    .foregroundStyle(Color("OnBackground"))
            }
            
            ForEach(
                stride(from: 0, to: options.count, by: columns).map { $0 },
                id: \.self
            ) { index in
                
                HStack(spacing: 12) {
                    
                    ForEach(
                        options[index..<min(index + columns, options.count)],
                        id: \.self
                    ) { option in
                        
                        SelectionButton(
                            label: label(option),
                            selected: selection == option,
                            action: {
                                onSelection(option)
                            }
                        )
                    }
                    
                    // Makes the last option only take up half of the width if it is an odd number of options
//                    if (options.count - index) < columns {
//                        Spacer()
//                            .frame(maxWidth: .infinity)
//                    }
                }
            }
        }
    }
}

#Preview("Security Key") {
    @Previewable @State var selectedKey = SecurityKey.CUSTOM
    
    SelectionButtonRow<SecurityKey>(
        options: SecurityKey.allCases,
        selection: $selectedKey,
        onSelection: { option in
            selectedKey = option
        },
        label: { option in
            return option.rawValue
        },
        description: "Test description"
    )
}
