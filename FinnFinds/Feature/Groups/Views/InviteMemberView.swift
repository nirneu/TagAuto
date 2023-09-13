//
//  AddMemberView.swift
//  FinnFinds
//
//  Created by Nir Neuman on 17/08/2023.
//

import SwiftUI

struct InviteMemberView: View {
    @EnvironmentObject var vm: GroupsViewModelImpl
    @EnvironmentObject var sessionService: SessionServiceImpl

    @Binding var showingSheet: Bool
    
    @State private var memberEmail = ""
    @State private var isInputError = false
    @State private var inputError = ""
    
    let group: GroupDetails
    
    var body: some View {
        
        NavigationStack {
            
            VStack(spacing: 32) {
                
                VStack(spacing: 16) {
                    
                    InputTextFieldView(text: $memberEmail, placeholder: "Member's Email", keyboardType: .emailAddress, sfSymbol: "envelope")
                    
                }
                
                ButtonView(title: "Send Invitation", handler: {
                    
                    self.isInputError = false
                    self.inputError = ""
                    
                    let invitationEmailNoSpaces = memberEmail.trimmingCharacters(in: .whitespaces).lowercased()
                    
                    let currentUserEmail = sessionService.userDetails?.userEmail.lowercased()
                    
                    // Check if the user isn't trying to invite himself
                    if currentUserEmail != invitationEmailNoSpaces {
                        
                        let membersEmails = vm.memberDetails.map { $0.userEmail }
                        
                        // Check if the user isn't trying to invite existing group members
                        if !membersEmails.contains(invitationEmailNoSpaces) {
                            vm.sendInvitation(to: invitationEmailNoSpaces.lowercased(), for: group.id, groupName: group.name)
                            
                            showingSheet = false
                    
                        } else {
                            self.isInputError = true
                            self.inputError = "This email already belongs to a group member. You cannot invite someone who is already a member."
                        }

                    } else {
                        self.isInputError = true
                        self.inputError = "This email is associated with your current account. You cannot invite yourself."
                    }
                    
                }, disabled: Binding<Bool>(
                    get: { memberEmail.trimmingCharacters(in: .whitespaces).isEmpty },
                    set: { _ in }
                ))
                
                if isInputError {
                    Text(inputError)
                        .foregroundColor(.red)
                }
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