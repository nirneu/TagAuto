//
//  CreateGroup.swift
//  FindCar
//
//  Created by Nir Neuman on 01/08/2023.
//

import SwiftUI

struct CreateGroup: View {
    
    @StateObject private var vm = RegistrationViewModelImpl(service: RegistrationServiceImpl())
    
    var body: some View {
        
        NavigationStack {
            
            VStack(spacing: 32) {
                
                VStack(spacing: 16) {
                    
                    InputTextFieldView(text: $vm.userDetails.email, placeholder: "Name", keyboardType: .namePhonePad, sfSymbol: nil)
                    
                    Divider()
                    
                    InputTextFieldView(text: $vm.userDetails.firstName, placeholder: "First Name", keyboardType: .namePhonePad, sfSymbol: nil)
                    
                    InputTextFieldView(text: $vm.userDetails.lastName, placeholder: "Last Name", keyboardType: .namePhonePad, sfSymbol: nil)
                    
                }
                
                ButtonView(title: "Create") {
                    vm.register()
                }
            }
            .padding(.horizontal, 15)
            .navigationTitle("Create Group")
            .alert("Error", isPresented: $vm.hasError) {
                Button("OK", role: .cancel) { }
            } message: {
                if case .failed(let error) = vm.state {
                    Text(error.localizedDescription)
                } else {
                    Text("Something went wrong")
                }
            }
            .applyClose()
            
        }
    }
}

struct CreateGroup_Previews: PreviewProvider {
    static var previews: some View {
        CreateGroup()
    }
}
