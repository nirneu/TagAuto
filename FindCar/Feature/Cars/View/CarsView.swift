//
//  CarsView.swift
//  FindCar
//
//  Created by Nir Neuman on 04/08/2023.
//

import SwiftUI

struct CarsView: View {
    
    @EnvironmentObject var sessionService: SessionServiceImpl
    
    @StateObject private var vm = CarsViewModelImpl(service: CarsServiceImpl())
    
    @State private var showLocationUpdateAlert = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            
            Text("Cars")
                .font(.system(.title2, weight: .bold))
                .padding([.leading, .top])
            
            List {
                
//                ForEach(Car.mockCars, id: \.self) { car in
//                    HStack {
//                        Image(systemName: "car.fill")
//                        Text(car.name)
//
//                        Spacer()
//
//                        HStack(spacing: 20) {
//
//                            Button {
//                                vm.selectCar(car)
//                            } label: {
//                                Image(systemName: vm.selectedCar == car ? "location.fill" : "location")
//                            }
//                            Button {
//                                vm.selectCar(car)
//                                self.showLocationUpdateAlert = true
//                            } label: {
//                                Image(systemName: "mappin.and.ellipse")
//                            }
//                            .alert("Update Location", isPresented: $showLocationUpdateAlert) {
//                                Button("Confirm", action: {
//                                    // code to update location
//                                    vm.updateCarLocation(car)
//                                    self.showLocationUpdateAlert = false
//                                })
//                                Button("Cancel", role: .cancel) {
//                                    self.showLocationUpdateAlert = false
//                                }
//                            }
//                        }
//
//                    }
//                    .frame(height: 40)
//                }
                
                if vm.isLoading {
                    ProgressView()
                } else {
            
                    if !vm.cars.isEmpty {
                        
                        ForEach(vm.cars, id: \.self) { car in
                            HStack {
                                Image(systemName: "car.fill")
                                Text(car.name)
                                
                                Spacer()
                                
                                HStack(spacing: 20) {
                                    
                                    Button {
                                        vm.selectCar(car)
                                    } label: {
                                        Image(systemName: vm.selectedCar == car ? "location.fill" : "location")
                                    }
                                    Button {
                                        vm.selectCar(car)
                                        self.showLocationUpdateAlert = true
                                    } label: {
                                        Image(systemName: "mappin.and.ellipse")
                                    }
                                    .alert("Update Location", isPresented: $showLocationUpdateAlert) {
                                        Button("Confirm", action: {
                                            // code to update location
                                            vm.updateCarLocation(car)
                                            self.showLocationUpdateAlert = false
                                        })
                                        Button("Cancel", role: .cancel) {
                                            self.showLocationUpdateAlert = false
                                        }
                                    }
                                }
                            }
                        }
                        .frame(height: 40)
                    } else {
                        
                        Text("You still don't have cars. Go ahead for the Groups section to add one.")
                    }
                }
            }
            .onAppear {
                if let userId = sessionService.userDetails?.userId {
                    vm.fetchUserCars(userId: userId)
                }
            }
            .onChange(of: sessionService.userDetails) { newUserDetails in
                if let userId = newUserDetails?.userId {
                    vm.fetchUserCars(userId: userId)
                }
            }
            .listStyle(.plain)
            
            .alert("Error", isPresented: $vm.hasError) {
                Button("OK", role: .cancel) { }
            } message: {
                if case .failed(let error) = vm.state {
                    Text(error.localizedDescription)
                } else {
                    Text("Something went wrong")
                }
            }
        }
    }
    
}


struct CarsView_Previews: PreviewProvider {
    static var previews: some View {
        
        let sessionService = SessionServiceImpl()
        
        CarsView()
            .environmentObject(sessionService)
    }
}
