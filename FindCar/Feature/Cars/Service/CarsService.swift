//
//  CarsService.swift
//  FindCar
//
//  Created by Nir Neuman on 04/08/2023.
//

import Foundation
import Combine
import FirebaseFirestore
import CoreLocation

enum CarKeys: String {
    case id
    case name
    case location
}

protocol CarsService {
    func getCars(of groupId: String) -> AnyPublisher<[Car], Error>
    func updateCarLocation(_ car: Car, location: CLLocation) -> AnyPublisher<Void, Error>
    func getAddress(from geopoint: CLLocationCoordinate2D) -> AnyPublisher<String, Error>
}

final class CarsServiceImpl: CarsService {
    
    private let db = Firestore.firestore()
    private let groupsPath = "groups"
    private let usersPath = "users"
    private let carsPath = "cars"
    
    func getCars(of userId: String) -> AnyPublisher<[Car], Error> {
        
        Deferred {
            
            Future { promise in
                
                let docRef = self.db.collection(self.usersPath).document(userId)
                
                docRef.getDocument { (document, error) in
                    
                    if let error = error {
                        
                        promise(.failure(error))
                        
                    } else if let document = document, document.exists, let groupsIds = document.data()?[self.groupsPath] as? [String] {
                        
                        let groupRefs = groupsIds.map { self.db.collection(self.groupsPath).document($0) }
                        var cars: [Car] = []
                        let dispatchGroup = DispatchGroup()
                        
                        for groupRef in groupRefs {
                            
                            dispatchGroup.enter()
                            
                            groupRef.getDocument { (document, error) in
                                
                                if let error = error {
                                    promise(.failure(error))
                                    dispatchGroup.leave()
                                } else if let document = document, document.exists, let carIds = document.data()?[self.carsPath] as? [String] {
                                    
                                    let carsRef = carIds.map { self.db.collection(self.carsPath).document($0) }
                                    
                                    for carRef in carsRef {
                                        
                                        dispatchGroup.enter()
                                        
                                        carRef.getDocument { (document, error) in
                                            
                                            if let error = error {
                                                promise(.failure(error))
                                            } else if let document = document, document.exists, let data = document.data() {
                                                
                                                let car = Car(id: document.documentID, name: data[CarKeys.name.rawValue] as? String ?? "", location: data[CarKeys.location.rawValue] as? GeoPoint ?? GeoPoint(latitude: 0, longitude: 0))
                                                cars.append(car)
                                                
                                            }
                                            dispatchGroup.leave()
                                        }
                                    }
                                }
                                dispatchGroup.leave()
                            }
                        }
                        
                        dispatchGroup.notify(queue: .main) {
                            promise(.success(cars))
                        }
                        
                    } else {
                        
                        promise(.failure(NSError(domain: "No document found", code: 404)))
                        
                    }
                }
            }
        }
        .receive (on: RunLoop.main)
        .eraseToAnyPublisher()
    }
    
    
    func updateCarLocation(_ car: Car, location: CLLocation) -> AnyPublisher<Void, Error> {
        
        Deferred {
            
            Future { promise in
                
                // create the GeoPoint for the new location
                let geoPoint = GeoPoint(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
                
                // update the location in Firestore
                self.db.collection(self.carsPath).document(car.id).updateData([
                    CarKeys.location.rawValue: geoPoint
                ]) { error in
                    if let error = error {
                        promise(.failure(error))
                    } else {
                        promise(.success(()))
                    }
                }
            }
        }
        .receive (on: RunLoop.main)
        .eraseToAnyPublisher()
    }
    
    func getAddress(from geopoint: CLLocationCoordinate2D) -> AnyPublisher<String, Error> {
        
        Deferred {
            
            Future { promise in
                
                let geocoder = CLGeocoder()
                let location = CLLocation(latitude: geopoint.latitude, longitude: geopoint.longitude)
                
                geocoder.reverseGeocodeLocation(location) { (placemarks, error) in
                    if let error = error {
                        promise(.failure(error))
                        return
                    }
                    
                    if let placemark = placemarks?.first {
                        let number = placemark.subThoroughfare ?? ""
                        let street = placemark.thoroughfare ?? ""
                        let city = placemark.locality ?? ""
                        let state = placemark.administrativeArea ?? ""
                        let zipCode = placemark.postalCode ?? ""
                        let country = placemark.country ?? ""
                        
                        let addressString = "\(street) \(number), \(city)"
                        promise(.success(addressString))
                    } else {
                        promise(.failure(CLError(.locationUnknown)))
                    }
                }
            }
        }
        .receive(on: RunLoop.main)
        .eraseToAnyPublisher()
    }
    
}
