//
//  Car.swift
//  FindCar
//
//  Created by Nir Neuman on 04/08/2023.
//

import Foundation
import FirebaseFirestore
import Combine

struct Car: Hashable, Identifiable {
    let id: String
    let name: String
    var location: GeoPoint
    
    var dictionary: [String: Any] {
        return [
            "id": id,
            "name": name,
            "location": location
        ]
    }
}

extension Car {
    static var mockCars: [Car] {
        [Car(id: "C1", name: "Car1", location: GeoPoint(latitude: 37.7749, longitude: -122.4194)),
         Car(id: "C2", name: "Car2", location: GeoPoint(latitude: 40.7128, longitude: -74.0060)),
         Car(id: "C3", name: "Car3", location: GeoPoint(latitude: 51.5074, longitude: -0.1278)),
         Car(id: "C4", name: "Car4", location: GeoPoint(latitude: 52.5200, longitude: 13.4050)),
         Car(id: "C5", name: "Car5", location: GeoPoint(latitude: 48.8566, longitude: 2.3522)),
         Car(id: "C6", name: "Car6", location: GeoPoint(latitude: 35.6895, longitude: 139.6917))]
    }
    
    static var new: Car {
        Car(id: "", name: "", location: GeoPoint(latitude: 0, longitude: 0))
    }
}