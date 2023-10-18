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
            Map(coordinateRegion: region, interactionModes: .all, showsUserLocation: true, annotationItems: carsViewModel.cars.filter { $0.location.latitude != 0 && $0.location.longitude != 0 }) { car in
                
                MapAnnotation(coordinate: CLLocationCoordinate2D(latitude: car.location.latitude, longitude: car.location.longitude)) {
                    VStack {
                        Text(car.icon)
                        
                        if car.currentlyInUse {
                            Text(car.name)
                                .font(.system(.caption))
                                .foregroundStyle(.gray)
                            HStack(spacing: 5) {
                                Image(systemName: "exclamationmark.circle")
                                Text("Unavailable")
                            }
                            .font(.system(.caption))
                            .foregroundStyle(.gray)

                        } else {
                            Text(car.name).font(.system(.caption, weight: .bold))
                        }
                    }
                    .onTapGesture {
                        Task {
                            await carsViewModel.selectCar(car)
                        }
                    }
                }
            
                
            }
            .gesture(DragGesture().onChanged({ newValue in
                mapViewModel.isCurrentLocationClicked = false
            }))
            .ignoresSafeArea(edges: .top)
            .onAppear {
                
                if let userId = sessionService.userDetails?.userId {
                    carsViewModel.fetchUserCars(userId: userId)
                }
                
            }
            .onChange(of: carsViewModel.selectedCar) { selectedCar in
                
                guard let coordinate = selectedCar?.location else { return }
                
                // Only if a car has a location show it on the map
                if coordinate.latitude != 0 && coordinate.longitude != 0 {
                    
                    let region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: coordinate.latitude - Constants.defaultSubtractionForMapAnnotation, longitude: coordinate.longitude), span: MapDetails.defaultSpan)
                    DispatchQueue.main.async {
                        mapViewModel.region = region
                    }
                }
                
                mapViewModel.isCurrentLocationClicked = false
                
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
                // Center the camera focus in proportion with the bottom sheet
                let centeredLocation = CLLocationCoordinate2D(latitude: location.coordinate.latitude - Constants.defaultSubtractionForMapAnnotation, longitude: location.coordinate.longitude)
                mapViewModel.region = MKCoordinateRegion(center: centeredLocation, span: MapDetails.defaultSpan)
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
