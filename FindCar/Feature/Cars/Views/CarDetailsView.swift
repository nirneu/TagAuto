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
    @EnvironmentObject var mapViewModel: MapViewModelImpl
    
    @State private var showLocationUpdateAlert = false
    @State private var showNoteParkingAlert = false
    @State private var carToUpdate: Car?
    @State private var selectedCar: Car?
    @State private var locationText: String = ""
    
    var car: Car
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 10) {
            
            VStack {
                if carsViewModel.isLoading {
                    ProgressView()
                } else {
                    
                    if carsViewModel.carAdress.isEmpty {
                        HStack {
                            Image(systemName: "exclamationmark.circle")
                            Text("The vehicle doesn't have a location yet")
                        }
                    } else {
                        VStack(alignment: .leading) {
                            Text("Last Known Address:")
                                .bold()
                            Text(carsViewModel.carAdress)
                                .foregroundColor(.gray)
                            
                        }
                        .padding(.bottom, 5)
                    }
                    
                }
            }
            HStack {
                Button {
                    carToUpdate = car
                    self.showLocationUpdateAlert = true
                } label: {
                    Image(systemName: "mappin.and.ellipse")
                    Text("Update Location")
                }
                .buttonStyle(.borderedProminent)
                .cornerRadius(50)
                
//                Button {
//                    self.showNoteParkingAlert = true
//                } label: {
//                    Image(systemName: "note.text")
//                    Text("Take a Note")
//                }
//                .buttonStyle(.borderedProminent)
            }
               
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .onAppear {
            carsViewModel.selectCar(car)
            carsViewModel.carNewNote = ""
            carsViewModel.getAddress(car: car, geopoint: car.locationCorodinate)
        }
        .sheet(isPresented: $showLocationUpdateAlert,onDismiss: {
            mapViewModel.pickedLocation = nil
            mapViewModel.pickedPlaceMark = nil
            mapViewModel.searchText = ""
            mapViewModel.mapView.removeAnnotations(mapViewModel.mapView.annotations)
            DispatchQueue.main.async {
                if let userId = sessionService.userDetails?.userId {
                    carsViewModel.isLoadingCars = true
                    carsViewModel.fetchUserCars(userId: userId)
                }
            }
        }, content: {
        
            SearchView(showingSheet: $showLocationUpdateAlert, car: car)
                .environmentObject(mapViewModel)
                .environmentObject(carsViewModel)
                .environmentObject(sessionService)
                .presentationDragIndicator(.visible)
            
        })
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
        
        CarDetailsView(car: Car.new)
            .environmentObject(sessionService)
            .environmentObject(carsViewModel)
    }
}
