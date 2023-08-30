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
    @State private var locationText: String = ""
    
    var carId: String
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 10) {
            
            VStack(alignment: .leading, spacing: 10) {
                if carsViewModel.isLoading {
                    ProgressView()
                } else {
                    
                    if carsViewModel.currentCarInfo.adress.isEmpty {
                        HStack {
                            Image(systemName: "exclamationmark.circle")
                            Text("The vehicle doesn't have a location yet")
                        }
                    } else {
                        VStack(alignment: .leading) {
                            Text("Last Known Address:")
                                .bold()
                            
                            Text(carsViewModel.currentCarInfo.adress)
                                .foregroundColor(.gray)
                            
                        }
                        .padding(.bottom, 5)
                    }
                    
                    if carsViewModel.currentCarInfo.currentlyInUse {
                        
                        VStack(alignment: .leading) {
                            Text("Currently used by:")
                                .bold()
                            
                            Text(carsViewModel.currentCarInfo.currentlyUsedByFullName)
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            HStack {
                
                if carsViewModel.currentCarInfo.currentlyInUse {
                    
                    if let userDetails = sessionService.userDetails {
                        
                        if userDetails.userId == carsViewModel.currentCarInfo.currentlyUsedById {
                            Button {
                                self.showLocationUpdateAlert = true
                            } label: {
                                Image(systemName: "mappin.and.ellipse")
                                Text("Park Vehicle")
                            }
                            .buttonStyle(.borderedProminent)
                            .cornerRadius(50)
                            
                        } else {
                            Button {
                                carsViewModel.markCarAsUsed(carId: carId, userId: userDetails.userId, userFullName: userDetails.firstName + " " + userDetails.lastName)
                            } label: {
                                Image(systemName: "person.badge.key")
                                Text("Mark as using")
                            }
                            .buttonStyle(.borderedProminent)
                            .cornerRadius(50)
                        }
                    }
                    
                } else {
                    Button {
                        if let userDetails = sessionService.userDetails {
                            carsViewModel.markCarAsUsed(carId: carId, userId: userDetails.userId, userFullName: userDetails.firstName + " " + userDetails.lastName)
                        }
                    } label: {
                        Image(systemName: "person.badge.key")
                        Text("Mark as using")
                    }
                    .buttonStyle(.borderedProminent)
                    .cornerRadius(50)
                }
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .onAppear {
            carsViewModel.carNewNote = ""
            carsViewModel.getCar(carId: carId)
        }
        .sheet(isPresented: $showLocationUpdateAlert,onDismiss: {
            mapViewModel.pickedLocation = nil
            mapViewModel.pickedPlaceMark = nil
            mapViewModel.searchText = ""
            mapViewModel.mapView.removeAnnotations(mapViewModel.mapView.annotations)
        }, content: {
            
            SearchView(showingSheet: $showLocationUpdateAlert, car: carsViewModel.currentCarInfo)
                .environmentObject(mapViewModel)
                .environmentObject(carsViewModel)
                .environmentObject(sessionService)
                .presentationDragIndicator(.visible)
            
        })
    }
}

struct CarDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        
        let sessionService = SessionServiceImpl()
        let carsViewModel = CarsViewModelImpl(service: CarsServiceImpl())
        let mapViewModel = MapViewModelImpl()
        
        @State var selectedCar: Car?
        
        CarDetailsView(carId: Car.new.id)
            .environmentObject(sessionService)
            .environmentObject(carsViewModel)
            .environmentObject(mapViewModel)
    }
}
