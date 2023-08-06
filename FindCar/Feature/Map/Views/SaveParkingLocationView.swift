////
////  SaveParkingLocationView.swift
////  FindCar
////
////  Created by Nir Neuman on 06/08/2023.
////
//
//import SwiftUI
//
//struct SaveParkingLocationView: View {
//    
//    @EnvironmentObject var vm: MapViewModelImpl
//    
//    @Binding var showingSheet: Bool
//    
//    @State private var carName = ""
//    
//    var body: some View {
//        
//        NavigationStack {
//            
//            VStack(spacing: 32) {
//                
//                VStack(spacing: 16) {
//                    
////                    InputTextFieldView(text: $carName, placeholder: "Car Name", keyboardType: .default, sfSymbol: nil)
//                }
//                
////                ButtonView(title: "Add Car", handler: {
////                    if !carName.trimmingCharacters(in: .whitespaces).isEmpty {
////                        vm.addCarToGroup(groupId: group.id, car: Car(id: "", name: carName, location: GeoPoint(latitude: 0, longitude: 0)))
////                    }
////                    showingSheet = false
////                }, disabled: Binding<Bool>(
////                    get: { carName.trimmingCharacters(in: .whitespaces).isEmpty },
////                    set: { _ in }
////                ))
//            }
//            .padding(.horizontal, 15)
//            .navigationTitle("Save Prking Location")
////            .alert("Error", isPresented: $vm.hasError) {
////                Button("OK", role: .cancel) { }
////            } message: {
////                if case .failed(let error) = vm.state {
////                    Text(error.localizedDescription)
////                } else {
////                    Text("Something went wrong")
////                }
////            }
//            .applyClose()
//        }
//        
//    }
//}
//
//struct SaveParkingLocationView_Previews: PreviewProvider {
//    static var previews: some View {
//        SaveParkingLocationView()
//    }
//}
