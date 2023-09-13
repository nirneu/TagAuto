//
//  MapView.swift
//  FinnFinds
//
//  Created by Nir Neuman on 26/07/2023.
//

import SwiftUI
import MapKit

struct MapView: View {
    
    @EnvironmentObject var mapViewModel: MapViewModelImpl
    @EnvironmentObject var carsViewModel: CarsViewModelImpl
    @EnvironmentObject var sessionService: SessionServiceImpl
    
    @State var tracking = MapUserTrackingMode.follow
    
    private var region : Binding<MKCoordinateRegion> {
        
        Binding {
            
            mapViewModel.region
            
        } set: { region in
            
            DispatchQueue.main.async {
                mapViewModel.region = region
            }
        }
    }
    
    var body: some View {
        
        ZStack(alignment: .top) {
            Map(coordinateRegion: region, interactionModes: .all, showsUserLocation: true, userTrackingMode: $tracking, annotationItems: carsViewModel.cars.filter { $0.location.latitude != 0 && $0.location.longitude != 0 }) { car in
                
                MapAnnotation(coordinate: CLLocationCoordinate2D(latitude: car.location.latitude, longitude: car.location.longitude)) {
                    VStack {
                        Text(car.icon)
                        Text(car.name).font(.system(.caption, weight: .bold))
                    }
                    .onTapGesture {
                        carsViewModel.selectCar(car)
                    }
                }
            
                
            }
            .gesture(DragGesture().onChanged({ newValue in
                mapViewModel.isCurrentLocationClicked = false
            }))
            .ignoresSafeArea(edges: .top)
            .onAppear {
                
                mapViewModel.checkIfLocationServicesIsEnabled()
                if let userId = sessionService.userDetails?.userId {
                    carsViewModel.fetchUserCars(userId: userId)
                }
                
            }
            .onChange(of: carsViewModel.selectedCar) { selectedCar in
                
                guard let coordinate = selectedCar?.location else { return }
                
                // Only if a car has a location show it on the map
                if coordinate.latitude != 0 && coordinate.longitude != 0 {
                    let region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude), span: MapDetails.defaultSpan)
                    DispatchQueue.main.async {
                        mapViewModel.region = region
                    }
                }
                
                mapViewModel.isCurrentLocationClicked = false
                
            }
   
            .alert("Error", isPresented: $mapViewModel.hasError) {
                Button("OK", role: .cancel) { }
            } message: {
                if case .failed(let error) = mapViewModel.state {
                    Text(error.localizedDescription)
                } else if case .unauthorized(let reason) = mapViewModel.state {
                    Text(reason)
                } else {
                    Text("Something went wrong")
                }
            }
            
            HStack {
                
                Spacer()
                
                Button {
                    mapViewModel.getCurrentLocation()
                } label: {
                    Image(systemName: mapViewModel.isCurrentLocationClicked ? "location.fill" : "location")
                }
                .buttonStyle(.borderedProminent)
                .clipShape(Circle())
                .padding(.trailing, 5)
            }
            
        }
        .onChange(of: carsViewModel.currentLocationFocus) { newLocation in
            if let location = newLocation {
                mapViewModel.region = MKCoordinateRegion( center: location.coordinate, span: MapDetails.defaultSpan)
            }
        }
    }
}

struct MapView_Previews: PreviewProvider {
    static var previews: some View {
        
        let carsViewModel = CarsViewModelImpl(service: CarsServiceImpl())
        let mapViewModel = MapViewModelImpl()
        let sessionService = SessionServiceImpl()
        
        MapView()
            .environmentObject(carsViewModel)
            .environmentObject(sessionService)
            .environmentObject(mapViewModel)
        
    }
}
