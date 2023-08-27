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
        
        VStack(alignment: .leading) {
            
            if carsViewModel.isLoading {
                ProgressView()
            } else {
                
                if carsViewModel.carAdress.isEmpty {
                    HStack {
                        Image(systemName: "exclamationmark.circle")
                        Text("The car doesn't have a location yet")
                    }
                } else {
                    VStack(alignment: .leading) {
                        Text("Last Known Adress:")
                            .bold()
                        Text(carsViewModel.carAdress)
                            .foregroundColor(.gray)

                    }
                    .padding(.bottom, 5)
                }
                
                if !carsViewModel.carNewNote.isEmpty {
                    VStack(alignment: .leading) {
                        Text("Last Written Note:")
                            .bold()
                        Text(carsViewModel.carNewNote)
                            .foregroundColor(.gray)

                    }
                } else if !car.note.isEmpty {
                    VStack(alignment: .leading) {
                        Text("Last Written Note:")
                            .bold()
                        Text(car.note)
                            .foregroundColor(.gray)

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
                
                Button {
                    self.showNoteParkingAlert = true
                } label: {
                    Image(systemName: "note.text")
                    Text("Take a Note")
                }
                .buttonStyle(.borderedProminent)
            }
                 
        }
        .navigationTitle(car.name)
        .navigationBarTitleDisplayMode(.inline)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(maxHeight: .infinity, alignment: .top)
        .padding([.leading, .trailing])
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
