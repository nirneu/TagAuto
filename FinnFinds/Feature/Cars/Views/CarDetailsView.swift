//
//  CarView.swift
//  FinnFinds
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
        
        VStack(alignment: .leading, spacing: 20) {
            
            if carsViewModel.isLoading {
                ProgressView()
            } else {
                
                VStack(alignment: .leading, spacing: 10) {
                    
                    if carsViewModel.currentCarInfo.address.isEmpty {
                        HStack {
                            Image(systemName: "exclamationmark.circle")
                            Text("The vehicle doesn't have a location yet")
                        }
                    } else {
                        VStack(alignment: .leading) {
                            Text("Last Known Address:")
                                .bold()
                            
                            Text(carsViewModel.currentCarInfo.address)
                                .foregroundColor(.gray)
                            
                        }
                        .padding(.bottom, 5)
                        .font(.system(.headline))
                        
                    }
                    
                    if carsViewModel.currentCarInfo.currentlyInUse {
                        
                        VStack(alignment: .leading) {
                            Text("Currently used by:")
                                .bold()
                            
                            Text(carsViewModel.currentCarInfo.currentlyUsedByFullName)
                                .foregroundColor(.gray)
                        }
                        .font(.system(.headline))
                        
                    }
                }
                
                HStack {
                    
                    if let userDetails = sessionService.userDetails {
                        
                        if userDetails.userId != carsViewModel.currentCarInfo.currentlyUsedById {
                            
                            Button {
                                Task {
                                    await carsViewModel.markCarAsUsed(carId: carId, userId: userDetails.userId, userFullName: userDetails.firstName + " " + userDetails.lastName)
                                }
                            } label: {
                                Image(systemName: "person.badge.key")
                                Text("Claim")
                            }
                            .buttonStyle(.borderedProminent)
                            .cornerRadius(50)
                            .font(.title2)
                        }
                        
                    }
                    
                    Button {
                        self.showLocationUpdateAlert = true
                    } label: {
                        Image(systemName: "mappin.and.ellipse")
                        Text("Park")
                    }
                    .buttonStyle(.borderedProminent)
                    .cornerRadius(50)
                    .font(.title2)
                    
                }
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .onAppear {
            Task {
                await carsViewModel.getCar(carId: carId)
            }
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
        
        CarDetailsView(carId: Car.new.id)
            .environmentObject(sessionService)
            .environmentObject(carsViewModel)
            .environmentObject(mapViewModel)
    }
}
