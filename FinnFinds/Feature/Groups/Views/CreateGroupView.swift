//
//  CreateGroup.swift
//  FinnFinds
//
//  Created by Nir Neuman on 01/08/2023.
//

import SwiftUI

struct CreateGroupView: View {
    
    @EnvironmentObject var sessionService: SessionServiceImpl
    @EnvironmentObject var vm: GroupsViewModelImpl
    
    @Binding var showingSheet: Bool
    
    var body: some View {
        
        NavigationStack {
            
            ScrollView {
                
                VStack(spacing: 32) {
                    
                    VStack(spacing: 16) {
                        
                        InputTextFieldView(text: $vm.groupDetails.name, placeholder: "Name", keyboardType: .namePhonePad, sfSymbol: nil)
                        
                    }
                    
                    ButtonView(title: "Create", handler: {
                        if let userId = sessionService.userDetails?.userId, !userId.isEmpty {
                            vm.groupDetails.members.append(userId)
                            vm.createGroup()
                        }
                        showingSheet = false
                    }, disabled: Binding<Bool>(
                        get: { vm.groupDetails.name.trimmingCharacters(in: .whitespaces).isEmpty ||
                            sessionService.userDetails?.userId == nil ||
                            sessionService.userDetails?.userId.trimmingCharacters(in: .whitespaces).isEmpty ?? true },
                        set: { _ in }
                    ))
                    
                }
                .padding([.horizontal, .top], 15)
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
}

struct CreateGroup_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = GroupsViewModelImpl(service: GroupsServiceImpl())

        CreateGroupView(showingSheet: .constant(true))
            .environmentObject(viewModel)

    }
}
