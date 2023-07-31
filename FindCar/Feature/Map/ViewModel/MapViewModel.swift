//
//  MapViewModel.swift
//  FindCar
//
//  Created by Nir Neuman on 26/07/2023.
//

import MapKit

enum MapDetails {
    static let startingLocation = CLLocationCoordinate2D(latitude: 37.331516, longitude: -121.891054)
    static let defaultSpan = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
}

enum LocationAuthState {
    case successfull
    case unauthorized(reason: String)
    case failed(error: Error)
    case na
}

enum LocationAuthMessages {
    static let turnOnLocation = "This app needs your location to find it on the map. Please enable location services in your phone's settings."
    static let unauthorized = "Your location is restricted."
    static let denied = "You have denied this app location permission. Got into settings to change it."
    static let cantRetrieve = "No location data has ever been retrieved."
}

protocol MapViewModel {
    var locationManager: CLLocationManager? { get }
    var region: MKCoordinateRegion { get }
    var state: LocationAuthState { get }
    var hasError: Bool { get }
    func checkIfLocationServicesIsEnabled()
    init()
}

final class MapViewModelImpl: NSObject, ObservableObject, MapViewModel {
    
    @Published var state: LocationAuthState = .na
    @Published var hasError: Bool = false
    @Published var region = MKCoordinateRegion(center: MapDetails.startingLocation, span: MapDetails.defaultSpan)
    
    var locationManager: CLLocationManager?
    
    override init() {
        super.init()
        setupErrorSubscription()
    }
    
    func checkIfLocationServicesIsEnabled() {
        
        if CLLocationManager.locationServicesEnabled() {
            
            locationManager = CLLocationManager()
            locationManager!.delegate = self
            
        } else {
            
            self.state = .unauthorized(reason: LocationAuthMessages.turnOnLocation)
            
        }
    }
    
    private func checkLocationAuthorization() {
        
        guard let locationManager = locationManager else { return }
        
        switch locationManager.authorizationStatus {
            
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .restricted:
            self.state = .unauthorized(reason: LocationAuthMessages.unauthorized)
        case .denied:
            self.state = .unauthorized(reason: LocationAuthMessages.denied)
        case .authorizedAlways, .authorizedWhenInUse:
            if let location = locationManager.location {
                region = MKCoordinateRegion(center: location.coordinate,
                                            span: MapDetails.defaultSpan)
            } else {
                self.state = .unauthorized(reason: LocationAuthMessages.cantRetrieve)
            }
        @unknown default:
            self.state = .unauthorized(reason: LocationAuthMessages.cantRetrieve)
        }
    }
    
}

//MARK: - CLLocationManagerDelegate
extension MapViewModelImpl: CLLocationManagerDelegate {
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        checkLocationAuthorization()
    }
}

//MARK: - Error handling
private extension MapViewModelImpl {
    
    func setupErrorSubscription() {
        $state.map { state -> Bool in
            switch state {
            case .successfull, .na:
                return false
            case .unauthorized:
                return true
            case .failed:
                return true
            }
        }
        .assign(to: &$hasError)
    }
    
}
