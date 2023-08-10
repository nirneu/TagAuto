//
//  CarsView.swift
//  FindCar
//
//  Created by Nir Neuman on 04/08/2023.
//

import SwiftUI

struct CarsView: View {
    
    @EnvironmentObject var sessionService: SessionServiceImpl
    @EnvironmentObject var carsViewModel: CarsViewModelImpl
    
    @State private var showLocationUpdateAlert = false
    @State private var carToUpdate: Car?
    @State private var selectedCar: Car?
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 0) {
            
            Text("Cars")
                .font(.system(.title2, weight: .bold))
                .padding([.leading, .top])
            
            List {
                
                if carsViewModel.isLoading {
                    ProgressView()
                } else {
                    
                    if !carsViewModel.cars.isEmpty {
                        
                        ForEach(carsViewModel.cars, id: \.self) { car in
                            
                            HStack {
                                
                                Button {
                                    self.showLocationUpdateAlert = false
                                    carsViewModel.selectCar(car)
                                    selectedCar = car
                                } label: {
                                    HStack {
                                        Image(systemName: "car.fill")
                                        Text(car.name)
                                    }
                                }
                                                    
                                Spacer()
                                          
                                Divider()
                                
                                Button {
                                    carToUpdate = car
                                    self.showLocationUpdateAlert = true
                                } label: {
                                    Image(systemName: "mappin.and.ellipse")
                                }
                                .buttonStyle(.borderless)
                                
                            }
                            .listRowBackground(selectedCar == car ? Color.gray.opacity(0.3) : Color.clear)
                        }
                        .frame(height: 40)

                        
                    } else {
                        
                        Text("You still don't have cars. Go ahead for the Groups section to add one.")
                    }
                }
            }
            .alert("Location Update", isPresented: $showLocationUpdateAlert) {
                Button("Confirm", action: {
                    if let updatingCar = carToUpdate {
                        carsViewModel.updateCarLocation(updatingCar)
                        if let userId = sessionService.userDetails?.userId {
                            carsViewModel.fetchUserCars(userId: userId)
                        }
                        self.showLocationUpdateAlert = false
                    }
                })
                Button("Cancel", role: .cancel) {
                    self.showLocationUpdateAlert = false
                }
            } message: {
                Text("Set the car's location to your current position?")
            }
            .onAppear {
                if let userId = sessionService.userDetails?.userId {
                    carsViewModel.fetchUserCars(userId: userId)
                }
                selectedCar = nil
            }
            .onChange(of: sessionService.userDetails) { newUserDetails in
                if let userId = newUserDetails?.userId {
                    carsViewModel.fetchUserCars(userId: userId)
                }
            }
            .listStyle(.plain)
            .alert("Error", isPresented: $carsViewModel.hasError) {
                Button("OK", role: .cancel) { }
            } message: {
                if case .failed(let error) = carsViewModel.state {
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
        let carsViewModel = CarsViewModelImpl(service: CarsServiceImpl())
        
        CarsView()
            .environmentObject(sessionService)
            .environmentObject(carsViewModel)
        
    }
}
