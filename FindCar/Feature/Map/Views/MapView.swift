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
    
    @State var currentLocationOn: Bool = true
    
    var body: some View {
        
        ZStack(alignment: .top) {
            Map(coordinateRegion: $vm.region, showsUserLocation: true, annotationItems: carsViewModel.cars) { car in
                MapAnnotation(coordinate: CLLocationCoordinate2D(latitude: car.location.latitude, longitude: car.location.longitude)) {
                    Image(systemName: "car.side")
                    Text(car.name).font(.system(.caption, weight: .bold))
                }
            }
            .onAppear {
                vm.checkIfLocationServicesIsEnabled()
            }
            .onChange(of: carsViewModel.selectedCar) { selectedCar in
                guard let coordinate = selectedCar?.location else { return }
                let span = MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                let region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude), span: span)
                vm.region = region
                self.currentLocationOn = false
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
                    self.currentLocationOn = true
                    carsViewModel.selectedCar = nil
                } label: {
                    Image(systemName: currentLocationOn ? "location.fill" : "location")
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
        
        MapView()
            .environmentObject(carsViewModel)
        
    }
}
