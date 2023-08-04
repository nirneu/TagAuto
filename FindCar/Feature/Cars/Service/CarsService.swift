//
//  CarsService.swift
//  FindCar
//
//  Created by Nir Neuman on 04/08/2023.
//

import Foundation
import Combine
import FirebaseFirestore

protocol CarsService {
    func getCars(of groupId: String) -> AnyPublisher<[Car], Error>
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
                                    print("Error getting group details: \(error)")
                                    dispatchGroup.leave()
                                } else if let document = document, document.exists, let carNames = document.data()?[self.carsPath] as? [String] {
                                    let groupCars = carNames.map { Car(id: "", name: $0, location: GeoPoint(latitude: 0, longitude: 0)) }
                                    cars.append(contentsOf: groupCars)
                                    dispatchGroup.leave()
                                } else {
                                    dispatchGroup.leave()
                                }
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
    
}
