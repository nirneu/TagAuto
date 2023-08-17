//
//  AddMemberView.swift
//  FindCar
//
//  Created by Nir Neuman on 17/08/2023.
//

import SwiftUI

struct InviteMemberView: View {
    @EnvironmentObject var vm: GroupsViewModelImpl
    
    @Binding var showingSheet: Bool
    
    @State private var memberEmail = ""
    
    let group: GroupDetails
    
    var body: some View {
        
        NavigationStack {
            
            VStack(spacing: 32) {
                
                VStack(spacing: 16) {
                    
                    InputTextFieldView(text: $memberEmail, placeholder: "Member's Email", keyboardType: .emailAddress, sfSymbol: "envelope")
                }
                
                ButtonView(title: "Send Invitation", handler: {
                    if !memberEmail.trimmingCharacters(in: .whitespaces).isEmpty {
                        vm.sendInvitation(to: memberEmail.lowercased(), for: group.id, groupName: group.name)
                    }
                    showingSheet = false
                }, disabled: Binding<Bool>(
                    get: { memberEmail.trimmingCharacters(in: .whitespaces).isEmpty },
                    set: { _ in }
                ))
            }
            .padding(.horizontal, 15)
            .navigationTitle("Invite Member")
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

struct AddMemberView_Previews: PreviewProvider {
    static var previews: some View {
        
        let viewModel = GroupsViewModelImpl(service: GroupsServiceImpl())
        
        InviteMemberView(showingSheet: .constant(true), group: GroupDetails(id: "0", name: "Preview", members: [], cars: []))
            .environmentObject(viewModel)
        
    }
}
