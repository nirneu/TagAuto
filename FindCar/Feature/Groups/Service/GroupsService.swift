//
//  GroupsService.swift
//  FindCar
//
//  Created by Nir Neuman on 01/08/2023.
//

import Foundation
import Combine
import Firebase

protocol GroupsService {
    func getGroups(of userId: String) -> AnyPublisher<[String], Error>
}

final class GroupsServiceImpl: GroupsService {
    
    func getGroups(of userId: String) -> AnyPublisher<[String], Error> {
        
        Deferred {
            
            Future { promise in
                
                let db = Firestore.firestore()
                let docRef = db.collection("users").document(userId)

                docRef.getDocument { (document, error) in
                    if let error = error {
                        promise(.failure(error))
                    } else {
                        if let document = document, document.exists {
                            if let data = document.data(), let groups = data["groups"] as? [String] {
                                promise(.success(groups))
                            }
                        } else {
                            promise(.failure(NSError(domain: "No document found", code: 404)))
                        }
                    }
                }
            }
        }
        .receive (on: RunLoop.main)
        .eraseToAnyPublisher()
    }

}
