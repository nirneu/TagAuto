//
//  ButtonComponentView.swift
//  FinnFinds
//
//  Created by Nir Neuman on 13/07/2023.
//

import SwiftUI

struct ButtonView: View {

    typealias ActionHandler = () -> Void
    
    let title: String
    let background: Color
    let foreground: Color
    let border: Color
    @Binding var disabled: Bool
    let handler: ActionHandler

    private let cornerRadius: CGFloat = 50
    
    internal init(title: String, background: Color = .blue, foreground: Color = .white, border: Color = .clear, handler: @escaping ButtonView.ActionHandler, disabled: Binding<Bool> = .constant(false)) {
        self.title = title
        self.background = background
        self.foreground = foreground
        self.border = border
        self._disabled = disabled
        self.handler = handler
    }
    
    var body: some View {
        Button(action: handler) {
            Text(title)
        }
        .frame(maxWidth: .infinity, minHeight: 50, maxHeight: 50)
        .background(disabled ? Color.gray : background)
        .foregroundColor(foreground)
        .font(.system(size: 16, weight: .bold))
        .cornerRadius(cornerRadius)
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(border, lineWidth: 2)
        }
        .disabled(disabled)
    }
}

struct ButtonView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ButtonView(title: "Primary Button",  handler:  { }, disabled: Binding<Bool>(
                get: { "".isEmpty },
                set: { _ in }
            ))
                .preview(with: "Primary Button View")
        
            ButtonView(title: "Secondary Button", background: .clear, foreground: .blue, border: .blue) { }
                .preview(with: "Secondary Button View")
        }
    }
}
