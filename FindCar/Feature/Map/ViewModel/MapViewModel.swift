//
//  MapViewModel.swift
//  FindCar
//
//  Created by Nir Neuman on 26/07/2023.
//

import MapKit
import Combine
import FirebaseFirestore

enum MapDetails {
    static let startingLocation = CLLocationCoordinate2D(latitude: 37.331516, longitude: -121.891054)
    static let defaultSpan = MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
}

enum LocationAuthState {
    case successful
    case unauthorized(reason: String)
    case failed(error: Error)
    case na
}

enum LocationAuthMessages {
    static let turnOnLocation = "This app needs your location to find it on the map. Please enable location services in your phone's settings."
    static let unauthorized = "Your location is restricted."
    static let denied = "You have denied this app location permission. Go into settings to change it."
    static let cantRetrieve = "No location data has ever been retrieved."
}

protocol MapViewModel {
    var locationManager: CLLocationManager? { get }
    var service: MapService { get }
    var region: MKCoordinateRegion { get }
    var state: LocationAuthState { get }
    var hasError: Bool { get }
    func checkIfLocationServicesIsEnabled()
    func getCurrentLocation()
    func regionForCar(_ car: Car?) -> MKCoordinateRegion
    init(service: MapService)
}

final class MapViewModelImpl: NSObject, ObservableObject, MapViewModel {
    
    @Published var state: LocationAuthState = .na
    @Published var hasError: Bool = false
    @Published var region = MKCoordinateRegion(center: MapDetails.startingLocation, span: MapDetails.defaultSpan)
    @Published var selectedCoordinate: CLLocationCoordinate2D?
    
    var locationManager: CLLocationManager?
    
    let service: MapService
    
    private var subscriptions = Set<AnyCancellable>()
    
    init(service: MapService) {
        self.service = service
        super.init()
        setupErrorSubscription()
    }
    
    func checkIfLocationServicesIsEnabled() {
        DispatchQueue.main.async {
            self.locationManager = CLLocationManager()
            self.locationManager!.delegate = self
        }
    }
    
    func getCurrentLocation() {
        DispatchQueue.main.async {
            if let location = self.locationManager?.location {
                let currentLocation = MKCoordinateRegion(center: location.coordinate,
                                                         span: MapDetails.defaultSpan)
                self.region = currentLocation
            } else {
                self.state = .unauthorized(reason: LocationAuthMessages.cantRetrieve)
            }
        }
    }
    
    func regionForCar(_ car: Car?) -> MKCoordinateRegion {
        guard let coordinate = car?.location else { return self.region }
        let span = MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        return MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude), span: span)
    }
    
}

//MARK: - CLLocationManagerDelegate
extension MapViewModelImpl: CLLocationManagerDelegate {
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            switch manager.authorizationStatus {
            case .notDetermined:
                manager.requestWhenInUseAuthorization()
            case .restricted:
                self.state = .unauthorized(reason: LocationAuthMessages.unauthorized)
            case .denied:
                self.state = .unauthorized(reason: LocationAuthMessages.denied)
            case .authorizedAlways, .authorizedWhenInUse:
                if let location = manager.location {
                    DispatchQueue.main.async {
                        self.region = MKCoordinateRegion(center: location.coordinate,
                                                         span: MapDetails.defaultSpan)
                    }
                } else {
                    self.state = .unauthorized(reason: LocationAuthMessages.cantRetrieve)
                }
            @unknown default:
                self.state = .unauthorized(reason: LocationAuthMessages.cantRetrieve)
            }
        }
    }
    
}

//MARK: - Error handling
private extension MapViewModelImpl {
    
    func setupErrorSubscription() {
        $state.map { state -> Bool in
            switch state {
            case .successful, .na:
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

extension MKCoordinateRegion {
    
    func isApproximatelyEqual(to region: MKCoordinateRegion, tolerance: Double = 0.0001) -> Bool {
        let areLatitudesClose = abs(self.center.latitude - region.center.latitude) < tolerance
        let areLongitudesClose = abs(self.center.longitude - region.center.longitude) < tolerance
        let areLatitudeDeltasClose = abs(self.span.latitudeDelta - region.span.latitudeDelta) < tolerance
        let areLongitudeDeltasClose = abs(self.span.longitudeDelta - region.span.longitudeDelta) < tolerance
        
        return areLatitudesClose && areLongitudesClose && areLatitudeDeltasClose && areLongitudeDeltasClose
    }
    
}
