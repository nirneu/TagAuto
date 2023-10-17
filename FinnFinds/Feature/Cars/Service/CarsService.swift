//
//  CarsService.swift
//  FinnFinds
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
    case address
    case note
    case icon
    case group
    case currentlyInUse
    case currentlyUsedById
    case currentlyUsedByFullName
}

protocol CarsService {
//    func getCars(of groupId: String) -> AnyPublisher<[Car], Error>
    func getCars(of userId: String) async throws -> [Car]
    func getCar(carId: String) -> AnyPublisher<Car, Error>
    func updateCarLocation(_ car: Car, location: CLLocation) -> AnyPublisher<GeoPoint, Error>
    func markCarAsUsed(carId: String, userId: String, userFullName: String) -> AnyPublisher<Void, Error>
    func updateCarNote(_ car: Car, note: String) -> AnyPublisher<String, Error> 
    func getAddress(carId: String, geopoint: CLLocationCoordinate2D) -> AnyPublisher<String, Error>
    func getCarNote(_ car: Car) -> AnyPublisher<String, Error>
    func updateCarAddress(carId: String, address: String) -> AnyPublisher<Void, Error>
    func deleteCar(_ groupId: String, car: Car) -> AnyPublisher<Void, Error>
}

final class CarsServiceImpl: CarsService {
    
    private let db = Firestore.firestore()
    private let groupsPath = "groups"
    private let usersPath = "users"
    private let carsPath = "cars"
    
//    func getCars(of userId: String) -> AnyPublisher<[Car], Error> {
//        
//        Deferred {
//            
//            Future { promise in
//                
//                let docRef = self.db.collection(self.usersPath).document(userId)
//                
//                docRef.getDocument { (document, error) in
//                    
//                    if let error = error {
//                        
//                        promise(.failure(error))
//                        
//                    } else if let document = document, document.exists, let groupsIds = document.data()?[self.groupsPath] as? [String] {
//                        
//                        let groupRefs = groupsIds.map { self.db.collection(self.groupsPath).document($0) }
//                        var cars: [Car] = []
//                        let dispatchGroup = DispatchGroup()
//                        
//                        for groupRef in groupRefs {
//                            
//                            dispatchGroup.enter()
//                            
//                            groupRef.getDocument { (document, error) in
//                                
//                                if let error = error {
//                                    promise(.failure(error))
//                                    dispatchGroup.leave()
//                                } else if let document = document, document.exists, let carIds = document.data()?[self.carsPath] as? [String], let groupName = document.data()?["name"] as? String {
//                                    
//                                    let groupId = document.documentID
//                                    
//                                    let carsRef = carIds.map { self.db.collection(self.carsPath).document($0) }
//                                    
//                                    for carRef in carsRef {
//                                        
//                                        dispatchGroup.enter()
//                                        
//                                        carRef.getDocument { (document, error) in
//                                            
//                                            if let error = error {
//                                                promise(.failure(error))
//                                            } else if let document = document, document.exists, let data = document.data() {
//
//                                                let car = Car(id: document.documentID, name: data[CarKeys.name.rawValue] as? String ?? "", location: data[CarKeys.location.rawValue] as? GeoPoint ?? GeoPoint(latitude: 0, longitude: 0), address: data[CarKeys.address.rawValue] as? String ?? "", groupName: groupName, groupId: groupId, note: data[CarKeys.note.rawValue] as? String ?? "", icon: data[CarKeys.icon.rawValue] as? String ?? "", currentlyInUse: data[CarKeys.currentlyInUse.rawValue] as? Bool ?? false, currentlyUsedById: data[CarKeys.currentlyUsedById.rawValue] as? String ?? "", currentlyUsedByFullName: data[CarKeys.currentlyUsedByFullName.rawValue] as? String ?? "")
//                                                cars.append(car)
//                                                
//                                            }
//                                            dispatchGroup.leave()
//                                        }
//                                    }
//                                }
//                                dispatchGroup.leave()
//                            }
//                        }
//                        
//                        dispatchGroup.notify(queue: .main) {
//                            promise(.success(cars))
//                        }
//                        
//                    } else {
//                        promise(.success([]))
//                    }
//                }
//            }
//        }
//        .receive (on: RunLoop.main)
//        .eraseToAnyPublisher()
//    }
    
    func getCars(of userId: String) async throws -> [Car] {
        let docRef = self.db.collection(self.usersPath).document(userId)
        
        do {
            let document = try await docRef.getDocument()
            
            guard let documentData = document.data(),
                  let groupsIds = documentData[self.groupsPath] as? [String] else {
                return []
            }
            
            var cars: [Car] = []
            let groupRefs = groupsIds.map { self.db.collection(self.groupsPath).document($0) }
            
            for groupRef in groupRefs {
                do {
                    let groupDocument = try await groupRef.getDocument()
                    guard let groupData = groupDocument.data(),
                          let carIds = groupData[self.carsPath] as? [String],
                          let groupName = groupData["name"] as? String else {
                        continue
                    }
                    
                    let groupId = groupDocument.documentID
                    let carsRef = carIds.map { self.db.collection(self.carsPath).document($0) }
                    
                    for carRef in carsRef {
                        do {
                            let carDocument = try await carRef.getDocument()
                            guard let carData = carDocument.data() else {
                                continue
                            }
                            
                            let car = Car(
                                id: carDocument.documentID,
                                name: carData[CarKeys.name.rawValue] as? String ?? "",
                                location: carData[CarKeys.location.rawValue] as? GeoPoint ?? GeoPoint(latitude: 0, longitude: 0),
                                address: carData[CarKeys.address.rawValue] as? String ?? "",
                                groupName: groupName,
                                groupId: groupId,
                                note: carData[CarKeys.note.rawValue] as? String ?? "",
                                icon: carData[CarKeys.icon.rawValue] as? String ?? "",
                                currentlyInUse: carData[CarKeys.currentlyInUse.rawValue] as? Bool ?? false,
                                currentlyUsedById: carData[CarKeys.currentlyUsedById.rawValue] as? String ?? "",
                                currentlyUsedByFullName: carData[CarKeys.currentlyUsedByFullName.rawValue] as? String ?? ""
                            )
                            
                            cars.append(car)
                        } catch {
                            throw error
                        }
                    }
                } catch {
                    throw error
                }
            }
            
            return cars
        } catch {
            throw error
        }
    }

    
    func getCar(carId: String) -> AnyPublisher<Car, Error> {
        Deferred {
            
            Future { promise in
                
                self.db.collection(self.carsPath).document(carId).getDocument() { (document, error) in
                    if let error = error {
                        promise(.failure(error))
                    } else {
                        
                        if let document = document, document.exists, let data = document.data() {
                            let car = Car(id: document.documentID, name: data[CarKeys.name.rawValue] as? String ?? "", location: data[CarKeys.location.rawValue] as? GeoPoint ?? GeoPoint(latitude: 0, longitude: 0), address: data[CarKeys.address.rawValue] as? String ?? "", groupName: "", groupId: data[CarKeys.group.rawValue] as? String ?? "", note: data[CarKeys.note.rawValue] as? String ?? "", icon: data[CarKeys.icon.rawValue] as? String ?? "", currentlyInUse: data[CarKeys.currentlyInUse.rawValue] as? Bool ?? false, currentlyUsedById: data[CarKeys.currentlyUsedById.rawValue] as? String ?? "", currentlyUsedByFullName: data[CarKeys.currentlyUsedByFullName.rawValue] as? String ?? "")
                            
                            promise(.success(car))
                        }
                    }
                }
            }
        }
        .receive(on: RunLoop.main)
        .eraseToAnyPublisher()
    }

    func updateCarLocation(_ car: Car, location: CLLocation) -> AnyPublisher<GeoPoint, Error> {
        
        Deferred {
            
            Future { promise in
                
                // create the GeoPoint for the new location
                let geoPoint = GeoPoint(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
                
                // update the location in Firestore
                self.db.collection(self.carsPath).document(car.id).updateData([
                    CarKeys.location.rawValue: geoPoint,
                    // When someone parks there's no one using it anymore
                    CarKeys.currentlyInUse.rawValue: false,
                    CarKeys.currentlyUsedById.rawValue: "",
                    CarKeys.currentlyUsedByFullName.rawValue: "",
                ]) { error in
                    if let error = error {
                        promise(.failure(error))
                    } else {
                        promise(.success((geoPoint)))
                    }
                }
            }
        }
        .receive(on: RunLoop.main)
        .eraseToAnyPublisher()
    }
    
    func markCarAsUsed(carId: String, userId: String, userFullName: String) -> AnyPublisher<Void, Error> {
        
        Deferred {
            
            Future { promise in
                
                self.db.collection(self.carsPath).document(carId).updateData([
                    CarKeys.currentlyInUse.rawValue: true,
                    CarKeys.currentlyUsedById.rawValue: userId,
                    CarKeys.currentlyUsedByFullName.rawValue: userFullName
                ]) { error in
                    if let error = error {
                        promise(.failure(error))
                    } else {
                        promise(.success(()))
                    }
                }
            }
        }
        .receive(on: RunLoop.main)
        .eraseToAnyPublisher()
    }
    
    func updateCarNote(_ car: Car, note: String) -> AnyPublisher<String, Error> {
        
        Deferred {
            
            Future { promise in
                
                self.db.collection(self.carsPath).document(car.id).updateData([
                    CarKeys.note.rawValue: note,
                ]) { error in
                    if let error = error {
                        promise(.failure(error))
                    } else {
                        promise(.success(note))
                    }
                }
            }
        }
        .receive(on: RunLoop.main)
        .eraseToAnyPublisher()
    }
    
    func getCarNote(_ car: Car) -> AnyPublisher<String, Error> {
        
        Deferred {
            
            Future { promise in
                
                self.db.collection(self.carsPath).document(car.id).getDocument() { (document, error) in
                    if let error = error {
                        promise(.failure(error))
                    } else {
                        
                        if let document = document, document.exists, let note = document.data()?[CarKeys.note.rawValue] as? String {
                            promise(.success(note))
                        }
                    }
                }
            }
        }
        .receive(on: RunLoop.main)
        .eraseToAnyPublisher()
    }
    
    func getAddress(carId: String, geopoint: CLLocationCoordinate2D) -> AnyPublisher<String, Error> {
        
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
    
    func updateCarAddress(carId: String, address: String) -> AnyPublisher<Void, Error> {
        
        Deferred {
            
            Future { promise in
                
                self.db.collection(self.carsPath).document(carId).updateData([
                    CarKeys.address.rawValue: address,
                ]) { error in
                    if let error = error {
                        promise(.failure(error))
                    } else {
                        promise(.success(()))
                    }
                }
            }
        }
        .receive(on: RunLoop.main)
        .eraseToAnyPublisher()
    }
    
    func deleteCar(_ groupId: String, car: Car) -> AnyPublisher<Void, Error> {

        Deferred {
            Future { promise in

                // Delete the car from the 'cars' collection
                self.db.collection(self.carsPath).document(car.id).delete() { error in
                    if let error = error {
                        promise(.failure(error))
                        return
                    }

                    // Remove the car's ID from the respective group in the 'groups' collection
                    self.db.collection(self.groupsPath).document(groupId).updateData([
                        self.carsPath: FieldValue.arrayRemove([car.id])
                    ]) { error in
                        if let error = error {
                            promise(.failure(error))
                        } else {
                            promise(.success(()))
                        }
                    }
                }
            }
        }
        .receive(on: RunLoop.main)
        .eraseToAnyPublisher()
    }
    
}
