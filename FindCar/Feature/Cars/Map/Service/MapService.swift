//
//  MapService.swift
//  FindCar
//
//  Created by Nir Neuman on 31/07/2023.
//

import Foundation
import FirebaseFirestore
import Combine

struct Car: Hashable {
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

protocol MapService {
    func saveCarLocation(_ car: Car, groupId: String) -> AnyPublisher<Void, Error>
}

final class MapServiceImpl: MapService {
    
    func saveCarLocation(_ car: Car, groupId: String) -> AnyPublisher<Void, Error> {
        
        Deferred {
            
            Future { promise in
                
                let db = Firestore.firestore()
                let docRef = db.collection("groups").document(groupId)
                    .collection("cars").document(car.id)
                
                docRef.setData(car.dictionary) { error in
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
}
