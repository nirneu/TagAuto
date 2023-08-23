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
    @State private var showNoteParkingAlert = false
    @State private var carToUpdate: Car?
    @State private var selectedCar: Car?
    @State private var locationText: String = ""
    
    var car: Car
    
    var body: some View {
        
        VStack(alignment: .leading) {
            
            if carsViewModel.isLoading || carsViewModel.isLoadingLocationLatest {
                ProgressView()
            } else {
                
                if carsViewModel.isLocationLatest == true {
                    
                    if carsViewModel.carAdress.isEmpty {
                        HStack {
                            Image(systemName: "exclamationmark.circle")
                            Text("The car doesn't have a location yet")
                        }
                    } else {
                        Text(carsViewModel.carAdress)
                    }
                    
                } else {
                    
                    if !carsViewModel.carNewNote.isEmpty {
                        Text(carsViewModel.carNewNote)
                    } else if !car.note.isEmpty {
                        Text(car.note)
                    } else {
                        HStack {
                            Image(systemName: "exclamationmark.circle")
                            Text("The car doesn't have a location yet")
                        }
                    }
                    
                }
            }
            
            MapView()
                .environmentObject(carsViewModel)
                .frame(height: 250)
            
            Button {
                carToUpdate = car
                self.showLocationUpdateAlert = true
            } label: {
                Image(systemName: "mappin.and.ellipse")
                Text("Update Location")
            }
            .buttonStyle(.bordered)
            
            
            Text("Or")
            
            Button {
                self.showNoteParkingAlert = true
            } label: {
                Image(systemName: "note.text")
                Text("Note Parking Spot")
            }
            .buttonStyle(.bordered)
            
            Spacer()
            
        }
        .navigationTitle(car.name)
        .padding([.leading, .trailing])
        .onAppear {
            carsViewModel.selectCar(car)
            carsViewModel.carNewNote = ""
            carsViewModel.getIsLocationLatest(for: car)
            carsViewModel.getAddress(car: car, geopoint: car.locationCorodinate)
        }
        .alert("Update Location", isPresented: $showLocationUpdateAlert) {
            Button("Confirm", action: {
                if let updatingCar = carToUpdate {
                    carsViewModel.updateCarLocation(updatingCar)
                    carsViewModel.fetchUserCars(userId: sessionService.userDetails?.userId ?? "")
                    self.showLocationUpdateAlert = false
                }
            })
            Button("Cancel", role: .cancel) {
                self.showLocationUpdateAlert = false
            }
        } message: {
            Text("You are about to update the car's location to your current spot")
        }
        .alert("Note Parking Spot", isPresented: $showNoteParkingAlert, actions: {
            
            TextField(
                "Where have you parked?",
                text: $locationText
            )
            
            Button("Save", action: {
                if !locationText.isEmpty {
                    carsViewModel.updateCarNote(car: car, note: locationText)
                    if let userId = sessionService.userDetails?.userId {
                        carsViewModel.fetchUserCars(userId: userId)
                    }
                }
                self.showNoteParkingAlert = false
            })
            Button("Cancel", role: .cancel) {
                self.showNoteParkingAlert = false
            }
        }, message: {
            Text("Write down where you parked")
        })
    }
}

struct CarDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        
        let sessionService = SessionServiceImpl()
        let carsViewModel = CarsViewModelImpl(service: CarsServiceImpl())
        
        CarDetailsView(car: Car(id: "1", name: "Car A", location: GeoPoint(latitude: Car.mockCars.first!.location.latitude, longitude: Car.mockCars.first!.location.longitude), adress: "", groupName: "", note: "", isLocationLatest: true))
            .environmentObject(sessionService)
            .environmentObject(carsViewModel)
    }
}
