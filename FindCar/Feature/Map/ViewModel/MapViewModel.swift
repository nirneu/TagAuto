//
//  MapViewModel.swift
//  FindCar
//
//  Created by Nir Neuman on 26/07/2023.
//

import MapKit
import Combine
import FirebaseFirestore
import CoreLocation

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
    var newLocationRegion: MKCoordinateRegion { get }
    var state: LocationAuthState { get }
    var hasError: Bool { get }
    func checkIfLocationServicesIsEnabled()
    func getCurrentLocation()
    func getCurrentLocationForNewLocationMap()
    func regionForCar(_ car: Car?) -> MKCoordinateRegion
    init(service: MapService)
}

final class MapViewModelImpl: NSObject, ObservableObject, MapViewModel, MKMapViewDelegate{
    
    //MARK: Properties
    @Published var mapView: MKMapView = .init()
    @Published var manager: CLLocationManager = .init()
    
    //MARK: Search Bar Text
    @Published var searchText: String = ""
    @Published var fetchedPlaces: [CLPlacemark]?
    
    //MARK: User Location
    @Published var userLocation: CLLocation?
    
    //MARK: Final Location
    @Published var pickedLocation: CLLocation?
    @Published var pickedPlaceMark: CLPlacemark?
    
    @Published var state: LocationAuthState = .na
    @Published var hasError: Bool = false
    @Published var region = MKCoordinateRegion(center: MapDetails.startingLocation, span: MapDetails.defaultSpan)
    @Published var isCurrentLocationClicked = true
    @Published var newLocationRegion = MKCoordinateRegion(center: MapDetails.startingLocation, span: MapDetails.defaultSpan)
    @Published var selectedCoordinate: CLLocationCoordinate2D?
    
    var locationManager: CLLocationManager?
    
    let service: MapService
    
    private var subscriptions = Set<AnyCancellable>()
    
    var cancellable: AnyCancellable?
    
    init(service: MapService) {
        self.service = service
        super.init()
        setupErrorSubscription()
        
        //MARK: Setting Delegates
        manager.delegate = self
        mapView.delegate = self
        
        //MARK: Requesting Location Access
        manager.requestWhenInUseAuthorization()
        
        //MARK: Search TextField Watching
        cancellable = $searchText
            .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink(receiveValue: { value in
                if value != "" {
                    self.fetchPlaces(value: value)
                } else {
                    self.fetchedPlaces = nil
                }
            })
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
                self.isCurrentLocationClicked = true
            } else {
                self.state = .unauthorized(reason: LocationAuthMessages.cantRetrieve)
            }
        }
    }
    
    func getCurrentLocationForNewLocationMap() {
        DispatchQueue.main.async {
            if let location = self.locationManager?.location {
                let currentLocation = MKCoordinateRegion(center: location.coordinate,
                                                         span: MapDetails.defaultSpan)
                self.newLocationRegion = currentLocation
            } else {
                self.state = .unauthorized(reason: LocationAuthMessages.cantRetrieve)
            }
        }
    }
    
    func fetchPlaces(value: String) {
        //MARK: Fetching places using MKLocalSearch & Async/Await
        Task {
            do {
                let request = MKLocalSearch.Request()
                request.naturalLanguageQuery = value.lowercased()
                request.region = self.region
                
                let response = try await MKLocalSearch(request: request).start()
                // We can also use Mainactor to publish changes in Main Thread
                await MainActor.run(body: {
                    self.fetchedPlaces = response.mapItems.compactMap({ item -> CLPlacemark? in
                        return item.placemark
                    })
                })
            } catch {
                 
            }
        }
    }
    
    func regionForCar(_ car: Car?) -> MKCoordinateRegion {
        guard let coordinate = car?.location else { return self.region }
        let span = MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        return MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude), span: span)
    }
    
    //MARK: Add Draggable Pin to MapView
    func addDragabblePin(coordinate: CLLocationCoordinate2D) {
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        annotation.title = "Tap and Drag to your parking spot"
        
        mapView.addAnnotation(annotation)
    }
    
    // MARK: Enabling Dragging
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let marker = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: "PARKINGPIN")
        marker.isDraggable = true
        marker.canShowCallout = false
        marker.glyphImage = UIImage(systemName: "mappin")
        marker.glyphTintColor = .black
        
        return marker
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, didChange newState: MKAnnotationView.DragState, fromOldState oldState: MKAnnotationView.DragState) {
        guard let newLocation = view.annotation?.coordinate else {return}
        self.pickedLocation = .init(latitude: newLocation.latitude, longitude: newLocation.longitude)
        updatePlacemark(location: .init(latitude: newLocation.latitude, longitude: newLocation.longitude))
    }
    
    func updatePlacemark(location: CLLocation) {
        Task {
            do {
                guard let place = try await reverseLocationCoordinates(location: location) else {return}
                await MainActor.run(body: {
                    self.pickedPlaceMark = place
                })
            } catch {
                
            }
        }
    }
    
    //MARK: Displaying New Location Data
    func reverseLocationCoordinates(location: CLLocation) async throws -> CLPlacemark? {
        let place = try await CLGeocoder().reverseGeocodeLocation(location).first
        return place
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
