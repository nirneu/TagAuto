//
//  RegistrationService.swift
//  FindCar
//
//  Created by Nir Neuman on 14/07/2023.
//

import Foundation
import Combine
import Firebase
import FirebaseFirestore

enum RegistrationKeys: String {
    case firstName
    case lastName
}

protocol RegistrationService {
    func register(with details: RegistrationDetails) -> AnyPublisher<Void, Error>
}

final class RegistrationServiceImpl: RegistrationService {
    
    func register(with details: RegistrationDetails) -> AnyPublisher<Void, Error> {
        
        Deferred {
            
            Future { promise in
                
                Auth.auth()
                    .createUser(withEmail: details.email, password: details.password) { res, err in
                        
                        if let err = err {
                            promise(.failure(err))
                        } else {
                            
                            if let uid = res?.user.uid {
                                
                                let values = [RegistrationKeys.firstName.rawValue: details.firstName,
                                              RegistrationKeys.lastName.rawValue: details.lastName] as [String: Any]
                                
                                let db = Firestore.firestore()
                                db.collection("users").document(uid).setData(values) { err in
                                    
                                    if let err = err {
                                        promise(.failure(err))
                                    } else {
                                        promise(.success(()))
                                    }
                                }
                                
                            } else {
                                promise(.failure(NSError(domain: "Invalid User Id", code: 0)))
                            }
                        }
                    }
            }
        }
        .receive (on: RunLoop.main)
        .eraseToAnyPublisher()
    }
}
