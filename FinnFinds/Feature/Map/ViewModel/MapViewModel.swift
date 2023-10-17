//
//  MapViewModel.swift
//  FinnFinds
//
//  Created by Nir Neuman on 26/07/2023.
//

import MapKit
import Combine
import FirebaseFirestore
import CoreLocation

enum MapDetails {
    static let startingLocation = CLLocationCoordinate2D(latitude: 37.331516, longitude: -121.891054)
    static let defaultCLLocationDegrees = 0.005
    static let defaultSpan = MKCoordinateSpan(latitudeDelta: defaultCLLocationDegrees, longitudeDelta: defaultCLLocationDegrees)
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
    var mapView: MKMapView { get }
    var manager: CLLocationManager { get }
    var searchText: String { get }
    var fetchedPlaces: [CLPlacemark]? { get }
    var userLocation: CLLocation? { get }
    var pickedLocation: CLLocation? { get }
    var pickedPlaceMark: CLPlacemark? { get }
    var locationManager: CLLocationManager? { get }
    var region: MKCoordinateRegion { get }
    var newLocationRegion: MKCoordinateRegion { get }
    var state: LocationAuthState { get }
    var hasError: Bool { get }
    var selectedCoordinate: CLLocationCoordinate2D? { get }
    var isCurrentLocationClicked: Bool { get }
    func checkIfLocationServicesIsEnabled()
    func getCurrentLocation()
    func getCurrentLocationForNewLocationMap()
    func fetchPlaces(value: String)
    func addDragabblePin(coordinate: CLLocationCoordinate2D)
    func updatePlacemark(location: CLLocation)
    init()
}

final class MapViewModelImpl: NSObject, ObservableObject, MapViewModel{
    
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
    
    private var subscriptions = Set<AnyCancellable>()
    
    private var cancellable: AnyCancellable?
    
    override init() {
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
    
    /// Get the current location of a user and show it inside the main map of the app
    func getCurrentLocation() {
        DispatchQueue.main.async {
            if let location = self.locationManager?.location {
                // Center the camera focus in proportion with the bottom sheet
                let centeredLocation = CLLocationCoordinate2D(latitude: location.coordinate.latitude - Constants.defaultSubtractionForMapAnnotation, longitude: location.coordinate.longitude)
                let currentLocation = MKCoordinateRegion(center: centeredLocation,
                                                         span: MapDetails.defaultSpan)
                self.region = currentLocation
                self.isCurrentLocationClicked = true
            } else {
                self.state = .unauthorized(reason: LocationAuthMessages.cantRetrieve)
                let currentLocation = MKCoordinateRegion(center: MapDetails.startingLocation,
                                                         span: MapDetails.defaultSpan)
                self.region = currentLocation
            }
        }
    }
    
}

//MARK: - CLLocationManagerDelegate
extension MapViewModelImpl: CLLocationManagerDelegate {
    
    /// Handle a cahnge of Auth in a location manager
    /// - Parameter manager: The location manager
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
                    // Center the camera focus in proportion with the bottom sheet
                    let centeredLocation = CLLocationCoordinate2D(latitude: location.coordinate.latitude - Constants.defaultSubtractionForMapAnnotation, longitude: location.coordinate.longitude)
                    DispatchQueue.main.async {
                        self.region = MKCoordinateRegion(center: centeredLocation, span: MapDetails.defaultSpan)
                    }
                } else {
                    // Center the camera focus in proportion with the bottom sheet
                    DispatchQueue.main.async {
                        self.region = MKCoordinateRegion(center: MapDetails.startingLocation, span: MapDetails.defaultSpan)
                    }
                    self.state = .unauthorized(reason: LocationAuthMessages.cantRetrieve)

                }
            @unknown default:
                // Center the camera focus in proportion with the bottom sheet
                DispatchQueue.main.async {
                    self.region = MKCoordinateRegion(center: MapDetails.startingLocation, span: MapDetails.defaultSpan)
                }
                self.state = .unauthorized(reason: LocationAuthMessages.cantRetrieve)

            }
        }
    }
    
}

//MARK: MKMapViewDelegate
extension MapViewModelImpl: MKMapViewDelegate {
    
    /// Enabling Dragging inside a MKAnnotationView and adding an annotaion for a new parking position of a car
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let marker = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: "PARKINGPIN")
        marker.isDraggable = true
        marker.isSelected = true
        marker.canShowCallout = false
        marker.glyphImage = UIImage(systemName: "mappin")
        marker.glyphTintColor = .black
        
        return marker
    }
    
    /// Handle a drag of an annotation in the map
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, didChange newState: MKAnnotationView.DragState, fromOldState oldState: MKAnnotationView.DragState) {
        guard let newLocation = view.annotation?.coordinate else {return}
        self.pickedLocation = .init(latitude: newLocation.latitude, longitude: newLocation.longitude)
        updatePlacemark(location: .init(latitude: newLocation.latitude, longitude: newLocation.longitude))
    }
    
    /// Get the current location on the map where the user choose a new location for a car
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
    
    /// Fetching locations ("Places") of a text using MKLocalSearch & Async/Await
    /// - Parameter value: Text of a generic place
    func fetchPlaces(value: String) {
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
    
    /// Add a draggable pin to MapView
    /// - Parameter coordinate: The coordinate in which the pin would be
    func addDragabblePin(coordinate: CLLocationCoordinate2D) {
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        annotation.title = "Drag to your parking spot"
        
        DispatchQueue.main.async {
            self.mapView.addAnnotation(annotation)
        }
    }
    
    /// Updates the view's current location address
    /// - Parameter location: The chosen location
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
    
    /// Displaying address of  CLLocation data
    /// - Parameter location: The location of the chosen place
    /// - Returns: The address of the chosen place
    private func reverseLocationCoordinates(location: CLLocation) async throws -> CLPlacemark? {
        let place = try await CLGeocoder().reverseGeocodeLocation(location).first
        return place
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
