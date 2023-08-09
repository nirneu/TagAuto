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
                                Image(systemName: "car.fill")
                                Text(car.name)
                                
                                Spacer()
                                
                                HStack(spacing: 20) {
                                    
                                    Button {
                                        self.showLocationUpdateAlert = false
                                        carsViewModel.selectCar(car)
                                    } label: {
                                        Image(systemName: "location.fill")
                                    }
                                    .buttonStyle(.borderless)
                                    
                                    
                                    Divider()
                                    Button {
                                        carsViewModel.selectCar(car)
                                        self.showLocationUpdateAlert = true
                                    } label: {
                                        Image(systemName: "mappin.and.ellipse")
                                    }
                                    .buttonStyle(.borderless)


                                    .alert("Location Update", isPresented: $showLocationUpdateAlert) {
                                        Button("Confirm", action: {
                                            carsViewModel.updateCarLocation(car)
                                            if let userId = sessionService.userDetails?.userId {
                                                carsViewModel.fetchUserCars(userId: userId)
                                            }
                                            self.showLocationUpdateAlert = false
                                        })
                                        Button("Cancel", role: .cancel) {
                                            self.showLocationUpdateAlert = false
                                        }
                                    } message: {
                                        Text("Set the car's location to your current position?")
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
                    carsViewModel.fetchUserCars(userId: userId)
                }
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
