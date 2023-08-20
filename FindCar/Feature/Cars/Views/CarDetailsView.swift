//
//  CarView.swift
//  FindCar
//
//  Created by Nir Neuman on 13/08/2023.
//

import SwiftUI
import FirebaseFirestore
import CoreLocation

struct CarDetailsView: View {
    
    @EnvironmentObject var sessionService: SessionServiceImpl
    @EnvironmentObject var carsViewModel: CarsViewModelImpl
    
    @State private var showLocationUpdateAlert = false
    @State private var carToUpdate: Car?
    @State private var selectedCar: Car?
    
    let car: Car
    
    var body: some View {
         
        VStack(alignment: .leading) {
            
            VStack(alignment: .leading) {
                Text(car.name)
                    .font(.system(.title2, weight: .bold))
                if carsViewModel.isLoading {
                    ProgressView()
                } else {
                    Text(carsViewModel.carAdress)
                }
            }
            .padding(.leading)
            
            HStack {
                
                Button {
                    carToUpdate = car
                    self.showLocationUpdateAlert = true
                } label: {
                    Image(systemName: "mappin.and.ellipse")
                    Text("Update location")
                }
                .buttonStyle(.bordered)
                Spacer()
            }
            .padding(.leading)
            Spacer()
        }
        .onAppear {
            carsViewModel.selectCar(car)
            carsViewModel.getAddress(from: car.locationCorodinate)
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
    }
}

struct CarDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        
        let sessionService = SessionServiceImpl()
        let carsViewModel = CarsViewModelImpl(service: CarsServiceImpl())
        
        CarDetailsView(car: Car(id: "1", name: "Car A", location: GeoPoint(latitude: Car.mockCars.first!.location.latitude, longitude: Car.mockCars.first!.location.longitude), groupName: ""))
            .environmentObject(sessionService)
            .environmentObject(carsViewModel)
    }
}
