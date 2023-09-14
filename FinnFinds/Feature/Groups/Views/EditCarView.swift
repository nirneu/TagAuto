//
//  EditCarView.swift
//  FinnFinds
//
//  Created by Nir Neuman on 28/08/2023.
//

import SwiftUI
import FirebaseFirestore

struct EditCarView: View {
    
    @EnvironmentObject var vm: GroupsViewModelImpl
        
    @State private var carName = ""
    @State private var selectedEmoji: String = ""
    
    @Environment(\.dismiss) var dismiss
    
    let group: GroupDetails
    let car: Car
    
    var body: some View {
        NavigationStack {
            
            ScrollView {
                
                VStack(spacing: 32) {
                    
                    VStack(spacing: 16) {
                        
                        InputTextFieldView(text: $carName, placeholder: "Car Name", keyboardType: .default, sfSymbol: nil)
                        
                        VehicleEmojiPicker(selectedEmoji: $selectedEmoji)
                    }
                    .padding(.top)
                    
                    ButtonView(title: "Edit Car", handler: {
                        if !carName.trimmingCharacters(in: .whitespaces).isEmpty && !selectedEmoji.isEmpty {
                            vm.updateCarDetails(Car(id: car.id, name: carName, location: car.location, adress: car.adress, groupName: car.groupName , groupId: car.groupId, note: car.note, icon: selectedEmoji, currentlyInUse: car.currentlyInUse, currentlyUsedById: car.currentlyUsedById, currentlyUsedByFullName: car.currentlyUsedByFullName))
                        }
                        dismiss()
                    }, disabled: Binding<Bool>(
                        get: { carName.trimmingCharacters(in: .whitespaces).isEmpty || selectedEmoji.isEmpty },
                        set: { _ in }
                    ))
                }
                .onAppear {
                    carName = car.name
                    selectedEmoji = car.icon
                }
                .padding(.horizontal, 15)
                .navigationTitle("Edit Car")
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

struct EditCarView_Previews: PreviewProvider {
    static var previews: some View {
        
        let viewModel = GroupsViewModelImpl(service: GroupsServiceImpl())

        EditCarView(group: GroupDetails(id: "0", name: "Preview", members: [], cars: []), car: Car.new)
            .environmentObject(viewModel)
    }
}
