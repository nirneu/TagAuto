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
    func getCars(of userId: String) async throws -> [Car]
    func getCar(carId: String) async throws -> Car
    func updateCarLocation(_ car: Car, location: CLLocation) async throws -> GeoPoint
    func markCarAsUsed(carId: String, userId: String, userFullName: String) async throws
    func getAddress(carId: String, geopoint: CLLocationCoordinate2D) async throws -> String
    func updateCarAddress(carId: String, address: String) async throws
    func deleteCar(_ groupId: String, car: Car) -> AnyPublisher<Void, Error>
}

final class CarsServiceImpl: CarsService {
    
    private let db = Firestore.firestore()
    private let groupsPath = "groups"
    private let usersPath = "users"
    private let carsPath = "cars"
    
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
    
    func getCar(carId: String) async throws -> Car {
        let document = try await self.db.collection(self.carsPath).document(carId).getDocument()
        
        if let data = document.data() {
            let car = Car(
                id: document.documentID,
                name: data[CarKeys.name.rawValue] as? String ?? "",
                location: data[CarKeys.location.rawValue] as? GeoPoint ?? GeoPoint(latitude: 0, longitude: 0),
                address: data[CarKeys.address.rawValue] as? String ?? "",
                groupName: "",
                groupId: data[CarKeys.group.rawValue] as? String ?? "",
                note: data[CarKeys.note.rawValue] as? String ?? "",
                icon: data[CarKeys.icon.rawValue] as? String ?? "",
                currentlyInUse: data[CarKeys.currentlyInUse.rawValue] as? Bool ?? false,
                currentlyUsedById: data[CarKeys.currentlyUsedById.rawValue] as? String ?? "",
                currentlyUsedByFullName: data[CarKeys.currentlyUsedByFullName.rawValue] as? String ?? ""
            )
            return car
        } else {
            throw NSError()
        }
    }
    
    func updateCarLocation(_ car: Car, location: CLLocation) async throws -> GeoPoint {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<GeoPoint, Error>) in
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
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: geoPoint)
                }
            }
        }
    }
    
    func markCarAsUsed(carId: String, userId: String, userFullName: String) async throws {
        try await self.db.collection(self.carsPath).document(carId).updateData([
            CarKeys.currentlyInUse.rawValue: true,
            CarKeys.currentlyUsedById.rawValue: userId,
            CarKeys.currentlyUsedByFullName.rawValue: userFullName
        ])
    }
    
    func getAddress(carId: String, geopoint: CLLocationCoordinate2D) async throws -> String {
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: geopoint.latitude, longitude: geopoint.longitude)
        
        return try await withCheckedThrowingContinuation { continuation in
            geocoder.reverseGeocodeLocation(location) { placemarks, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let placemark = placemarks?.first {
                    let number = placemark.subThoroughfare ?? ""
                    let street = placemark.thoroughfare ?? ""
                    let city = placemark.locality ?? ""
                    let addressString = "\(street) \(number), \(city)"
                    continuation.resume(returning: addressString)
                } else {
                    continuation.resume(throwing: CLError(.locationUnknown))
                }
            }
        }
    }
    
    func updateCarAddress(carId: String, address: String) async throws {
        try await self.db.collection(self.carsPath).document(carId).updateData([
            CarKeys.address.rawValue: address,
        ])
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
