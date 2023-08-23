//
//  CarsView.swift
//  FindCar
//
//  Created by Nir Neuman on 04/08/2023.
//

import SwiftUI

struct CarsView: View {
    
    @EnvironmentObject var sessionService: SessionServiceImpl
    
    @StateObject var carsViewModel = CarsViewModelImpl(service: CarsServiceImpl())
    
    @State private var showLocationUpdateAlert = false
    
    var mockCars: [Car]
    
    var body: some View {
        
        NavigationStack {
            
            List {
                
                if !mockCars.isEmpty {
                    let sortedUniqueCarsNames = Array(Set(mockCars.map { $0.groupName })).sorted(by: <)
                    
                    ForEach(sortedUniqueCarsNames) { groupName in
                        
                        Section(header: Text(groupName)) {
                            
                            ForEach(mockCars.filter { $0.groupName == groupName }.sorted(by: { $0.name < $1.name }), id: \.self) { car in
                                
                                NavigationLink {
                                    CarDetailsView(car: car)
                                        .environmentObject(sessionService)
                                        .environmentObject(carsViewModel)
                                } label: {
                                    Image(systemName: "car.fill")
                                        .font(.system(.title2))
                                    
                                    VStack(alignment: .leading) {
                                        Text(car.name)
                                            .font(.system(.headline, weight: .bold))
                                        if car.isLocationLatest {
                                            Text(car.adress)
                                        } else {
                                            Text(car.note)
                                        }
                                    }
                                }
                                
                            }
                            .frame(height: 40)
                            
                        }
                        
                    }
                } else {
                    if carsViewModel.isLoadingCars {
                        ProgressView()
                    } else {
                        
                        if !carsViewModel.cars.isEmpty {
                            
                            let sortedUniqueCarsNames = Array(Set(carsViewModel.cars.map { $0.groupName })).sorted(by: <)
                            
                            ForEach(sortedUniqueCarsNames) { groupName in
                                
                                Section(header: Text(groupName)) {
                                    
                                    ForEach(carsViewModel.cars.filter { $0.groupName == groupName }.sorted(by: { $0.name < $1.name }), id: \.self) { car in
                                        
                                        NavigationLink(destination: CarDetailsView(car: car)
                                            .environmentObject(sessionService)
                                            .environmentObject(carsViewModel)) {
                                                Image(systemName: "car.fill")
                                                    .font(.system(.title2))
                                                
                                                VStack(alignment: .leading) {
                                                    Text(car.name)
                                                        .font(.system(.headline, weight: .bold))
                                                    if car.isLocationLatest {
                                                        Text(car.adress)
                                                    } else {
                                                        Text(car.note)
                                                    }
                                                }
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
                
            }
            .navigationTitle("Cars")
            .onAppear {
                carsViewModel.fetchUserCars(userId: sessionService.userDetails?.userId ?? "")
            }
            .onChange(of: sessionService.userDetails) { newUserDetails in
                carsViewModel.fetchUserCars(userId: sessionService.userDetails?.userId ?? "")
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
        
        CarsView(mockCars: Car.mockCars)
            .environmentObject(sessionService)
            .environmentObject(carsViewModel)
        
    }
}

