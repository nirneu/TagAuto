//
//  CloseModifier.swift
//  FindCar
//
//  Created by Nir Neuman on 13/07/2023.
//

import SwiftUI

struct CloseModifier: ViewModifier {
    
    @Environment(\.dismiss) private var dismiss
    
    func body(content: Content) -> some View {
        
        content
            .toolbar {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                }
            }
    }
}

extension View {
    
    func applyClose() -> some View {
        self.modifier(CloseModifier())
    }
}
