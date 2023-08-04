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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            
            Text("Cars")
                .font(.system(.title2, weight: .bold))
                .padding([.leading, .top])
                
            List {
                if !vm.cars.isEmpty {
                    
                    ForEach(vm.cars, id: \.self) { car in
                        HStack {
                            Image(systemName: "car.fill")
                            Text(car.name)
                        }
                    }
                } else {
                    
                    ForEach(Car.mockCars, id: \.self) { car in
                        HStack {
                            Image(systemName: "car.fill")
                            Text(car.name)
                        }
                    }
                }
            }
            .onAppear {
                vm.fetchUserCars(userId: sessionService.userDetails?.userId ?? "")
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
