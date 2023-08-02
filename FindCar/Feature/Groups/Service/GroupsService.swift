//
//  GroupsService.swift
//  FindCar
//
//  Created by Nir Neuman on 01/08/2023.
//

import Foundation
import Combine
import Firebase

enum GroupKeys: String {
    case userId
    case name
    case members
    case cars
}

protocol GroupsService {
    func getGroups(of userId: String) -> AnyPublisher<[GroupDetails], Error>
    func createGroup(with details: GroupDetails) -> AnyPublisher<Void, Error>
    func fetchUserDetails(for userIds: [String]) -> AnyPublisher<[UserDetails], Error>
}

final class GroupsServiceImpl: GroupsService {
    
    func getGroups(of userId: String) -> AnyPublisher<[GroupDetails], Error> {
        
        Deferred {
            
            Future { promise in
                
                let db = Firestore.firestore()
                let docRef = db.collection("users").document(userId)
                
                docRef.getDocument { (document, error) in
                    
                    if let error = error {
                        promise(.failure(error))
                    } else if let document = document, document.exists, let groupIds = document.data()?["groups"] as? [String] {
                        
                        let groupRefs = groupIds.map { db.collection("groups").document($0) }
                        
                        let dispatchGroup = DispatchGroup()
                        var groupDetails: [GroupDetails] = []
                        
                        for groupRef in groupRefs {
                            
                            dispatchGroup.enter()
                            
                            groupRef.getDocument { (document, error) in
                                
                                if let error = error {
                                    print("Error getting group details: \(error)")
                                } else if let document = document, document.exists, let data = document.data() {
                                    let id = document.documentID
                                    let groupName = data[GroupKeys.name.rawValue] as? String ?? ""
                                    let members = data[GroupKeys.members.rawValue] as? [String] ?? []
                                    let cars = data[GroupKeys.cars.rawValue] as? [String] ?? []
                                    groupDetails.append(GroupDetails(id: id, name: groupName, members: members, cars: cars))
                                }
                                
                                dispatchGroup.leave()
                            }
                        }
                        
                        dispatchGroup.notify(queue: .main) {
                            promise(.success(groupDetails))
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
    
    
    
    func createGroup(with details: GroupDetails) -> AnyPublisher<Void, Error> {
        
        Deferred {
            
            Future { promise in
                
                let db = Firestore.firestore()
                
                let values = [GroupKeys.name.rawValue: details.name.trimmingCharacters(in: .whitespaces),
                              GroupKeys.members.rawValue: details.members] as [String: Any]
                
                var newGroupRef: DocumentReference? = nil
                
                newGroupRef = db.collection("groups").addDocument(data: values, completion: { error in
                    
                    if let error = error {
                        promise(.failure(error))
                    } else {
                        if let userId = details.members.first, let newGroupId = newGroupRef?.documentID {
                            let userDoc = db.collection("users").document(userId)
                            userDoc.updateData([
                                "groups": FieldValue.arrayUnion([newGroupId])
                            ]) { error in
                                if let error = error {
                                    promise(.failure(error))
                                } else {
                                    promise(.success(()))
                                }
                            }
                        } else {
                            promise(.success(()))
                        }
                    }
                })
            }
        }
        .receive (on: RunLoop.main)
        .eraseToAnyPublisher()
    }
    
    func fetchUserDetails(for userIds: [String]) -> AnyPublisher<[UserDetails], Error> {
        Deferred {
            Future { promise in
                let db = Firestore.firestore()
                let dispatchGroup = DispatchGroup()
                var userDetails: [UserDetails] = []
                
                for userId in userIds {
                    dispatchGroup.enter()
                    let docRef = db.collection("users").document(userId)

                    docRef.getDocument { (document, error) in
                        if let error = error {
                            print("Error getting user details: \(error)")
                            dispatchGroup.leave()
                        } else if let document = document, document.exists, let data = document.data() {
                            let firstName = data[RegistrationKeys.firstName.rawValue] as? String ?? ""
                            let lastName = data[RegistrationKeys.lastName.rawValue] as? String ?? ""
                            userDetails.append(UserDetails(userId: userId, firstName: firstName, lastName: lastName))
                            dispatchGroup.leave()
                        } else {
                            dispatchGroup.leave()
                        }
                    }
                }
                
                dispatchGroup.notify(queue: .main) {
                    promise(.success(userDetails))
                }
            }
        }
        .receive (on: RunLoop.main)
        .eraseToAnyPublisher()
    }

}
