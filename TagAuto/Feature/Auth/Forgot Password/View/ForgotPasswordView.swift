//
//  ForgotPasswordView.swift
//  TagAuto
//
//  Created by Nir Neuman on 14/07/2023.
//

import SwiftUI

struct ForgotPasswordView: View {
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = ForgotPasswordViewModelImpl(service: ForgotPasswordServiceImpl())
    
    var body: some View {
        
        NavigationStack {
            
            VStack(spacing: 16) {
                
                InputTextFieldView(text: $vm.email, placeholder: "Email", keyboardType: .emailAddress, sfSymbol: "envelope")
                
                ButtonView(title: "Send Password Reset") {
                    Task {
                        await vm.sendPasswordReset()
                        dismiss()
                    }
                    
                }
                
            }
            .padding(.horizontal, 15)
            .navigationTitle("Reset Password")
            .applyClose()
        }
    }
}

struct ForgotPasswordView_Previews: PreviewProvider {
    static var previews: some View {
        ForgotPasswordView()
    }
}
