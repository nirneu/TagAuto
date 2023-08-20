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
                        
                        let sortedUniqueGroupNames = Array(Set(carsViewModel.cars.map { $0.groupName })).sorted(by: <)

                        ForEach(sortedUniqueGroupNames) { groupName in
                            
                            Section(header: Text(groupName)) {
                                
                                ForEach(carsViewModel.cars.filter { $0.groupName == groupName }.sorted(by: { $0.name < $1.name }), id: \.self) { car in

                                        NavigationLink {
                                            CarDetailsView(car: car)
                                                .environmentObject(sessionService)
                                                .environmentObject(carsViewModel)
                                        } label: {
                                            Image(systemName: "car.fill")
                                            Text(car.name)
                                        }
                                        
                                }
                                .frame(height: 40)
                                
                            }
                            
                        }
                                 
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

extension String: Identifiable {
    public typealias ID = Int
    public var id: Int {
        return hash
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

