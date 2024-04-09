//
//  Car.swift
//  TagAuto
//
//  Created by Nir Neuman on 04/08/2023.
//

import Foundation
import FirebaseFirestore
import Combine
import CoreLocation

struct Car: Hashable, Identifiable {
    let id: String
    let name: String
    var location: GeoPoint
    let address: String
    let groupName: String
    let groupId: String
    var note: String
    let icon: String
    let currentlyInUse: Bool
    let currentlyUsedById: String
    let currentlyUsedByFullName: String
    
    var locationCorodinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
    }
}

extension Car {
    
    static var new: Car {
        Car(id: "", name: "", location: GeoPoint(latitude: 0, longitude: 0), address: "", groupName: "", groupId: "", note: "", icon: "", currentlyInUse: false, currentlyUsedById: "", currentlyUsedByFullName: "")
    }
}
