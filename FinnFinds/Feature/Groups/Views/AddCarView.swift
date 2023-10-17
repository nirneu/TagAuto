//
//  AddCarView.swift
//  FinnFinds
//
//  Created by Nir Neuman on 02/08/2023.
//

import SwiftUI
import FirebaseFirestore

struct AddCarView: View {

    @EnvironmentObject var vm: GroupsViewModelImpl
    
    @Binding var showingSheet: Bool
    
    @State private var carName = ""
    @State private var selectedEmoji: String = ""
    
    let group: GroupDetails

    var body: some View {
        
        NavigationStack {
            
            ScrollView {
                
                VStack(spacing: 32) {
                    
                    VStack(spacing: 16) {
                        
                        InputTextFieldView(text: $carName, placeholder: "Vehicle Name", keyboardType: .default, sfSymbol: nil)
                        
                        VehicleEmojiPicker(selectedEmoji: $selectedEmoji)
                        
                    }
                    .padding(.top)
                    
                    ButtonView(title: "Add Vehicle", handler: {
                        if !carName.trimmingCharacters(in: .whitespaces).isEmpty && !selectedEmoji.isEmpty {
                            vm.addCarToGroup(groupId: group.id, car: Car(id: "", name: carName, location: GeoPoint(latitude: 0, longitude: 0), address: "", groupName: "", groupId: "", note: "", icon: selectedEmoji, currentlyInUse: false, currentlyUsedById: "", currentlyUsedByFullName: ""))
                        }
                        showingSheet = false
                    }, disabled: Binding<Bool>(
                        get: { carName.trimmingCharacters(in: .whitespaces).isEmpty || selectedEmoji.isEmpty },
                        set: { _ in }
                    ))
                    
                }
                .padding(.horizontal, 15)
                .navigationTitle("Add Vehicle")
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

struct AddCarView_Previews: PreviewProvider {
    static var previews: some View {
        
        let viewModel = GroupsViewModelImpl(service: GroupsServiceImpl())
        
        AddCarView(showingSheet: .constant(true), group: GroupDetails(id: "0", name: "Preview", members: [], cars: []))
            .environmentObject(viewModel)
    }
}
