//
//  MapView.swift
//  FindCar
//
//  Created by Nir Neuman on 26/07/2023.
//

import SwiftUI
import MapKit

struct MapView: View {
    
    @StateObject private var vm = MapViewModelImpl(service: MapServiceImpl())
    
    @EnvironmentObject var carsViewModel: CarsViewModelImpl
    
    @EnvironmentObject var sessionService: SessionServiceImpl
    
    @State var tracking = MapUserTrackingMode.follow
    
    private var region : Binding<MKCoordinateRegion> {
        
        Binding {
            
            vm.region
            
        } set: { region in
            
            DispatchQueue.main.async {
                vm.region = region
                carsViewModel.selectedCar = nil
            }
        }
    }
    
    var body: some View {
        
        ZStack(alignment: .top) {
            Map(coordinateRegion: region, interactionModes: .all, showsUserLocation: true, userTrackingMode: $tracking, annotationItems: carsViewModel.cars) { car in
                MapAnnotation(coordinate: CLLocationCoordinate2D(latitude: car.location.latitude, longitude: car.location.longitude)) {
                    Image(systemName: "car.side")
                    Text(car.name).font(.system(.caption, weight: .bold))
                }
            }
            .onAppear {
                DispatchQueue.main.async {
                    
                    vm.checkIfLocationServicesIsEnabled()
                    if let userId = sessionService.userDetails?.userId {
                        carsViewModel.fetchUserCars(userId: userId)
                    }
                }
            }
            .onChange(of: carsViewModel.selectedCar) { selectedCar in
                guard let coordinate = selectedCar?.location else { return }
                let span = MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                let region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude), span: span)
                vm.region = region
            }
            .onChange(of: carsViewModel.currentLocationFocus) { newLocation in
                if let location = newLocation {
                    let span = MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)

                    vm.region = MKCoordinateRegion( center: location.coordinate, span: span)
                }
            }
            .alert("Error", isPresented: $vm.hasError) {
                Button("OK", role: .cancel) { }
            } message: {
                if case .failed(let error) = vm.state {
                    Text(error.localizedDescription)
                } else if case .unauthorized(let reason) = vm.state {
                    Text(reason)
                } else {
                    Text("Something went wrong")
                }
            }
            .navigationTitle("")
            
            HStack {
                
                Spacer()
                
                Button {
                    vm.getCurrentLocation()
                } label: {
                    Image(systemName: "location.fill" )
                }
                .buttonStyle(.borderedProminent)
                .padding(.trailing, 15)
                .padding(.top, 50)
            }
            
        }
    }
}

struct MapView_Previews: PreviewProvider {
    static var previews: some View {
        
        let carsViewModel = CarsViewModelImpl(service: CarsServiceImpl())
        let sessionService = SessionServiceImpl()

        MapView()
            .environmentObject(carsViewModel)
            .environmentObject(sessionService)
        
    }
}
