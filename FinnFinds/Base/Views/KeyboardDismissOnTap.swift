//
//  KeyboardDismissOnTap.swift
//  FinnFinds
//
//  Created by Nir Neuman on 13/09/2023.
//

import SwiftUI

extension View {
    
    // Dismiss keyboard on tap anywhere on the screen
    func endTextEditing() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                        to: nil, from: nil, for: nil)
    }
}
