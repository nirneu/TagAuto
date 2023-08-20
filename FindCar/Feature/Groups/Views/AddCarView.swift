//
//  AddCarView.swift
//  FindCar
//
//  Created by Nir Neuman on 02/08/2023.
//

import SwiftUI
import FirebaseFirestore

struct AddCarView: View {

    @EnvironmentObject var vm: GroupsViewModelImpl
    
    @Binding var showingSheet: Bool
    
    @State private var carName = ""
    
    let group: GroupDetails

    var body: some View {
        
        NavigationStack {
            
            VStack(spacing: 32) {
                
                VStack(spacing: 16) {
                    
                    InputTextFieldView(text: $carName, placeholder: "Car Name", keyboardType: .default, sfSymbol: nil)
                }
                
                ButtonView(title: "Add Car", handler: {
                    if !carName.trimmingCharacters(in: .whitespaces).isEmpty {
                        vm.addCarToGroup(groupId: group.id, car: Car(id: "", name: carName, location: GeoPoint(latitude: 0, longitude: 0), groupName: group.name))
                    }
                    showingSheet = false
                }, disabled: Binding<Bool>(
                    get: { carName.trimmingCharacters(in: .whitespaces).isEmpty },
                    set: { _ in }
                ))
            }
            .padding(.horizontal, 15)
            .navigationTitle("Add Car")
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

struct AddCarView_Previews: PreviewProvider {
    static var previews: some View {
        
        let viewModel = GroupsViewModelImpl(service: GroupsServiceImpl())
        
        AddCarView(showingSheet: .constant(true), group: GroupDetails(id: "0", name: "Preview", members: [], cars: []))
            .environmentObject(viewModel)
    }
}
