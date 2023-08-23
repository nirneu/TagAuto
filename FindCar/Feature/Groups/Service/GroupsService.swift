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

enum InvitationKeys: String {
    case id
    case email
    case groupId
    case groupName
}

protocol GroupsService {
    func getGroups(of userId: String) -> AnyPublisher<[GroupDetails], Error>
    func createGroup(with details: GroupDetails) -> AnyPublisher<Void, Error>
    func deleteGroup(_ groupId: String) -> AnyPublisher<Void, Error>
    func fetchUserDetails(for userIds: [String]) -> AnyPublisher<[UserDetails], Error>
    func addCarToGroup(_ groupId: String, car: Car) -> AnyPublisher<Void, Error>
    func deleteCar(_ groupId: String, car: Car) -> AnyPublisher<Void, Error>
    func sendInvitation(to email: String, for group: String, groupName: String) -> AnyPublisher<Void, Error>
    func deleteMember(userId: String, groupId: String) -> AnyPublisher<Void, Error>
    func getCars(of groupId: String) -> AnyPublisher<[Car], Error>
    func getMembersIds(of groupId: String) -> AnyPublisher<[String], Error>
}

final class GroupsServiceImpl: GroupsService {
    
    private let db = Firestore.firestore()
    private let groupsPath = "groups"
    private let usersPath = "users"
    private let membersPath = "members"
    private let carsPath = "cars"
    private let invitationsPath = "invitations"
    
    func getGroups(of userId: String) -> AnyPublisher<[GroupDetails], Error> {
        
        Deferred {
            
            Future { promise in
                
                let docRef = self.db.collection(self.usersPath).document(userId)
                
                docRef.getDocument { (document, error) in
                    
                    if let error = error {
                        promise(.failure(error))
                    } else if let document = document, document.exists, let groupIds = document.data()?[self.groupsPath] as? [String] {
                        
                        let groupRefs = groupIds.map { self.db.collection(self.groupsPath).document($0) }
                        
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
                        promise(.success([]))
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
                
                let values = [GroupKeys.name.rawValue: details.name.trimmingCharacters(in: .whitespaces),
                              GroupKeys.members.rawValue: details.members] as [String: Any]
                
                var newGroupRef: DocumentReference? = nil
                
                newGroupRef = self.db.collection(self.groupsPath).addDocument(data: values, completion: { error in
                    
                    if let error = error {
                        promise(.failure(error))
                    } else {
                        if let userId = details.members.first, let newGroupId = newGroupRef?.documentID {
                            let userDoc = self.db.collection(self.usersPath).document(userId)
                            userDoc.updateData([
                                self.groupsPath: FieldValue.arrayUnion([newGroupId])
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
    
    func deleteGroup(_ groupId: String) -> AnyPublisher<Void, Error> {
        Deferred {
            Future { promise in
                // Fetch the group document
                let groupDocRef = self.db.collection(self.groupsPath).document(groupId)
                
                groupDocRef.getDocument { (document, error) in
                    if let error = error {
                        promise(.failure(error))
                        return
                    }
                    
                    guard let document = document, document.exists,
                          let members = document.data()?["members"] as? [String] else {
                        promise(.failure(NSError(domain: "Group not found or members not found", code: 404)))
                        return
                    }

                    // Get cars if they exist, or default to an empty array
                    let cars = document.data()?["cars"] as? [String] ?? []
                    
                    let dispatchGroup = DispatchGroup()
                    var deletionError: Error? = nil
                    
                    // Iterate over the members and remove groupId from each member's groups
                    for memberId in members {
                        dispatchGroup.enter()
                        let userDocRef = self.db.collection(self.usersPath).document(memberId)
                        userDocRef.updateData([
                            self.groupsPath: FieldValue.arrayRemove([groupId])
                        ]) { error in
                            if let error = error {
                                deletionError = error
                            }
                            dispatchGroup.leave()
                        }
                    }
                    
                    // Iterate over the cars and delete each one from the cars collection
                    for carId in cars {
                        dispatchGroup.enter()
                        let carDocRef = self.db.collection(self.carsPath).document(carId)
                        carDocRef.delete() { error in
                            if let error = error {
                                deletionError = error
                            }
                            dispatchGroup.leave()
                        }
                    }
                    
                    dispatchGroup.notify(queue: .main) {
                        if let deletionError = deletionError {
                            promise(.failure(deletionError))
                            return
                        }
                        
                        // Delete the group itself after all members and cars have been processed
                        groupDocRef.delete() { error in
                            if let error = error {
                                promise(.failure(error))
                            } else {
                                promise(.success(()))
                            }
                        }
                    }
                }
            }
        }
        .receive(on: RunLoop.main)
        .eraseToAnyPublisher()
    }
    
    func fetchUserDetails(for userIds: [String]) -> AnyPublisher<[UserDetails], Error> {
        
        Deferred {
            
            Future { promise in
                let dispatchGroup = DispatchGroup()
                var userDetails: [UserDetails] = []
                
                for userId in userIds {
                    dispatchGroup.enter()
                    let docRef = self.db.collection(self.usersPath).document(userId)
                    
                    docRef.getDocument { (document, error) in
                        if let error = error {
                            print("Error getting user details: \(error)")
                            dispatchGroup.leave()
                        } else if let document = document, document.exists, let data = document.data() {
                            let firstName = data[RegistrationKeys.firstName.rawValue] as? String ?? ""
                            let lastName = data[RegistrationKeys.lastName.rawValue] as? String ?? ""
                            let userEmail = data[RegistrationKeys.userEmail.rawValue] as? String ?? ""
                            userDetails.append(UserDetails(userId: userId, userEmail: userEmail, firstName: firstName, lastName: lastName))
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
    
    func addCarToGroup(_ groupId: String, car: Car) -> AnyPublisher<Void, Error> {
        
        Deferred {
            
            Future { promise in
                
                var newCarRef: DocumentReference? = nil
                newCarRef = self.db.collection(self.carsPath).addDocument(data: [
                    "name": car.name,
                    "group": groupId
                ]) { error in
                    if let error = error {
                        promise(.failure(error))
                    } else {
                        // If the car document was created successfully, update the group
                        guard let newCarId = newCarRef?.documentID else {
                            promise(.failure(NSError(domain: "Couldn't get car ID", code: 404)))
                            return
                        }
                        
                        self.db.collection(self.groupsPath).document(groupId).updateData([
                            self.carsPath: FieldValue.arrayUnion([newCarId])
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
    
    func getCars(of groupId: String) -> AnyPublisher<[Car], Error> {
        
        Deferred {
            
            Future { promise in
                
                let docRef = self.db.collection(self.groupsPath).document(groupId)
                
                docRef.getDocument { (document, error) in
                    if let error = error {
                        promise(.failure(error))
                    } else if let document = document, document.exists, let carIds = document.data()?[self.carsPath] as? [String], let groupName = document.data()?["name"] as? String {
                        
                        var cars: [Car] = []
                        let dispatchGroup = DispatchGroup()
                        
                        for carId in carIds {
                            
                            dispatchGroup.enter()
                            
                            let carRef = self.db.collection("cars").document(carId)
                            carRef.getDocument { (document, error) in
                                
                                if let error = error {
                                    promise(.failure(error))
                                } else if let document = document, document.exists, let data = document.data() {
                                    
                                    let car = Car(id: document.documentID, name: data["name"] as? String ?? "", location: data["location"] as? GeoPoint ?? GeoPoint(latitude: 0, longitude: 0), groupName: groupName, note: data["note"] as? String ?? "", isLocationLatest: data["isLocationLatest"] as? Bool ?? true)
                                    cars.append(car)
                                    
                                }
                                dispatchGroup.leave()
                            }
                        }
                        
                        dispatchGroup.notify(queue: .main) {
                            promise(.success(cars))
                        }
                        
                    } else {
                        promise(.success([]))
                    }
                }
            }
        }
        .receive (on: RunLoop.main)
        .eraseToAnyPublisher()
    }
    
    func sendInvitation(to email: String, for groupId: String, groupName: String) -> AnyPublisher<Void, Error> {
        
        Deferred {
            
            Future { promise in
                
                self.db.collection(self.invitationsPath).addDocument(data: [
                    InvitationKeys.email.rawValue: email,
                    InvitationKeys.groupId.rawValue: groupId,
                    InvitationKeys.groupName.rawValue: groupName
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
    
    func deleteMember(userId: String, groupId: String) -> AnyPublisher<Void, Error> {
        Deferred {
            
            Future { promise in
                
                // Fetch the current members of the group
                self.db.collection(self.groupsPath).document(groupId).getDocument { (document, error) in
                    
                    if let error = error {
                        promise(.failure(error))
                        return
                    }
                    
                    guard let document = document, document.exists else {
                        promise(.failure(NSError(domain: "Document doesn't exist", code: 404)))
                        return
                    }
                    
                    if let members = document.data()?["members"] as? [String], members.count <= 1, members.contains(userId) {
                        promise(.failure(NSError(domain: "Cannot leave group with only one member", code: 403)))
                        return
                    }
                    
                    // Remove groupId from user's groups
                    self.db.collection(self.usersPath).document(userId).updateData([
                        self.groupsPath: FieldValue.arrayRemove([groupId])
                    ]) { error in
                        if let error = error {
                            promise(.failure(error))
                            return
                        }
                        
                        // Remove userId from members list of the group
                        self.db.collection(self.groupsPath).document(groupId).updateData([
                            self.membersPath: FieldValue.arrayRemove([userId])
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
        }
        .receive(on: RunLoop.main)
        .eraseToAnyPublisher()
    }

    func getMembersIds(of groupId: String) -> AnyPublisher<[String], Error> {
        
        Deferred {
            
            Future { promise in
                
                let docRef = self.db.collection(self.groupsPath).document(groupId)
                
                docRef.getDocument { (document, error) in
                    if let error = error {
                        promise(.failure(error))
                    } else if let document = document, document.exists, let membersIds = document.data()?[self.membersPath] as? [String] {
                        
                        promise(.success(membersIds))
                                                
                    } else {
                        promise(.success([]))
                    }
                }
            }
        }
        .receive (on: RunLoop.main)
        .eraseToAnyPublisher()
    }
    
}
