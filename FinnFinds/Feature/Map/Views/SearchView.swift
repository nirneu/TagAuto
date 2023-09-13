//
//  SearchView.swift
//  FinnFinds
//
//  Created by Nir Neuman on 25/08/2023.
//

import SwiftUI
import MapKit

struct SearchView: View {
    @EnvironmentObject var mapViewModel: MapViewModelImpl
    @EnvironmentObject var carsViewModel: CarsViewModelImpl
    @EnvironmentObject var sessionService: SessionServiceImpl

    //MARK: Navigation Tag to push View to MapView
    @State var presentNavigationView: Bool = false
    
    @Binding var showingSheet: Bool
    
    var car: Car
    
    var body: some View {
        
        NavigationStack {
            
            VStack {
                HStack(spacing: 15) {
                    
                    Text("Search Location")
                        .font(.title3)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Find locations here", text: $mapViewModel.searchText)
                }
                .padding(.vertical, 12)
                .padding(.horizontal)
                .background {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(.gray)
                }
                .padding(.vertical, 10)
                
                if let places = mapViewModel.fetchedPlaces, !places.isEmpty {
                    List {
                        ForEach(places, id: \.self) { place in
                            Button {
                                //MARK: Setting Map Region
                                if let coordinate = place.location?.coordinate {
                                    mapViewModel.pickedLocation = .init(latitude: coordinate.latitude, longitude: coordinate.longitude)
                                    mapViewModel.mapView.region = .init(center: coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)
                                    mapViewModel.addDragabblePin(coordinate: coordinate)
                                    mapViewModel.updatePlacemark(location: .init(latitude: coordinate.latitude, longitude: coordinate.longitude))
                                    
                                    // MARK: Navigating To MapView
                                    presentNavigationView.toggle()
                                    
                                }
                            } label: {
                                HStack(spacing: 15) {
                                    
                                    Image(systemName: "mappin.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.gray)
                                    
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(place.name ?? "")
                                            .font(.title3.bold())
                                            .foregroundColor(.primary)
                                        
                                        Text(place.locality ?? "")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                        
                                    }
                                }
                            }
                            
                        }
                    }
                    .listStyle(.plain)
                    
                } else {
                    //MARK: Live Location Button
                    Button {
                        
                        //MARK: Setting Map Region
                        let coordinate = mapViewModel.newLocationRegion.center
                        mapViewModel.pickedLocation = .init(latitude: coordinate.latitude, longitude: coordinate.longitude)
                        mapViewModel.mapView.region = .init(center: coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)
                        mapViewModel.addDragabblePin(coordinate: coordinate)
                        mapViewModel.updatePlacemark(location: .init(latitude: coordinate.latitude, longitude: coordinate.longitude))
                        
                        // MARK: Navigating To MapView
                        presentNavigationView.toggle()
                        
                        
                    } label: {
                        Label {
                            Text("Use Current Location")
                                .font(.callout)
                        } icon: {
                            Image(systemName: "location.north.circle.fill")
                        }
                        .foregroundColor(.green)
                    }
                    .frame(maxWidth: .infinity,alignment: .leading)
                    
                }
                
            }
            .onAppear {
                mapViewModel.getCurrentLocationForNewLocationMap()
            }

            .padding()
            .frame(maxHeight: .infinity,alignment: .top)
            .background{
                Rectangle()
                    .foregroundColor(.clear)
                    .navigationDestination(isPresented: $presentNavigationView, destination: {
                        MapViewSelection(showingSheet: $showingSheet, car: car)
                            .environmentObject(mapViewModel)
                            .environmentObject(carsViewModel)
                            .environmentObject(sessionService)
                            .toolbar(.hidden, for: .navigationBar)
                    })
                
            }
        }
    }
}

struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        
        @State var showingSheet = true
        
        SearchView(showingSheet: $showingSheet, car: Car.new)
    }
}

//MARK: MapView Live Selection
struct MapViewSelection: View {
    @EnvironmentObject var mapViewModel: MapViewModelImpl
    @EnvironmentObject var carsViewModel: CarsViewModelImpl
    @EnvironmentObject var sessionService: SessionServiceImpl
    @Environment(\.dismiss) var dismiss
    
    @Binding var showingSheet: Bool
    
    var car: Car
    
    var body: some View {
        ZStack {
            MapViewHelper()
                .environmentObject(mapViewModel)
                .ignoresSafeArea()
            
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title2)
//                    .foregroundColor(.gray)
                Text("Back")
//                    .foregroundColor(.gray)

            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            
            
            //MARK: Displaying Data
            if let place = mapViewModel.pickedPlaceMark {
                VStack(spacing: 15) {
                    Text("Confirm Vehicle's New Location")
                        .font(.title2.bold())
                    
                    HStack(spacing: 15) {
                        
                        Image(systemName: "mappin.circle.fill")
                            .font(.title2)
                            .foregroundColor(.gray)
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text(place.name ?? "")
                                .font(.title3.bold())
                            
                            Text(place.locality ?? "")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 10)
                        
                    HStack(spacing: 15) {
                        
                        Text(car.icon)
                            .font(.title2)
                        
                        Text(car.name)
                            .font(.title3.bold())
                        
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 10)
                    
                    Button {
                        if let pickedLcoation = mapViewModel.pickedLocation, let userId = sessionService.userDetails?.userId {
                            carsViewModel.updateCarLocation(car: car, newLocation: pickedLcoation, userId: userId)
                            showingSheet = false
                        }
                    } label: {
                        Text("Confirm Location")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background {
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(.green)
                            }
                            .foregroundColor(.white)
                    }
                }
                .padding()
                .background {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(.thinMaterial)
                        .ignoresSafeArea()
                }
                .frame(maxHeight: .infinity, alignment: .bottom)
            }
        }
        .onAppear {
            if let initialAnnotation = mapViewModel.mapView.annotations.first {
                DispatchQueue.main.async {
                    mapViewModel.mapView.selectAnnotation(initialAnnotation, animated: true)
                }
            }
        }
        .onDisappear {
            DispatchQueue.main.async {
                mapViewModel.mapView.removeAnnotations(mapViewModel.mapView.annotations)
            }
        }
    }
}

//MARK: UIKit MapView
struct MapViewHelper: UIViewRepresentable {
    @EnvironmentObject var mapViewModel: MapViewModelImpl
    
    func makeUIView(context: Context) -> MKMapView {
        return mapViewModel.mapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {}
}

