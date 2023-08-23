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
            Map(coordinateRegion: region, interactionModes: .all, showsUserLocation: true, userTrackingMode: $tracking, annotationItems: carsViewModel.cars.filter { $0.isLocationLatest }) { car in
                
                MapAnnotation(coordinate: CLLocationCoordinate2D(latitude: car.location.latitude, longitude: car.location.longitude)) {
                    Image(systemName: "car")
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
                
                guard let isLocationLatest = selectedCar?.isLocationLatest else { return }
                
                if isLocationLatest {
                    guard let coordinate = selectedCar?.location else { return }
                    
                    // Only if a car has a location show it on the map
                    if coordinate.latitude != 0 && coordinate.longitude != 0 {
                        let region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude), span: MapDetails.defaultSpan)
                        vm.region = region
                    }
                }
                
            }
            .onChange(of: carsViewModel.currentLocationFocus) { newLocation in
                if let location = newLocation {
                    
                    vm.region = MKCoordinateRegion( center: location.coordinate, span: MapDetails.defaultSpan)
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
            
            HStack {
                
                Spacer()
                
                Button {
                    vm.getCurrentLocation()
                } label: {
                    Image(systemName: "location.fill" )
                }
                .buttonStyle(.borderedProminent)
                .padding(.trailing, 15)
                .padding(.top, 10)
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
