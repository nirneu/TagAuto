//
//  AccountService.swift
//  TagAuto
//
//  Created by Nir Neuman on 17/08/2023.
//

import Foundation
import Combine
import FirebaseFirestore
import FirebaseAuth

protocol AccountService {
    func getInvitations(for accountEmail: String) -> AnyPublisher<[Invitation], Error>
    func acceptInvitation(userId: String, groupId: String, invitationId: String) -> AnyPublisher<Void, Error>
    func removeInvitation(_ invitationId: String) -> AnyPublisher<Void, Error>
    func deleteAccount(_ userId: String) async throws
}

final class AccountServiceImpl: AccountService {
    
    private let db = Firestore.firestore()
    private let groupsPath = "groups"
    private let usersPath = "users"
    private let membersPath = "members"
    private let carsPath = "cars"
    private let invitationsPath = "invitations"
    
    func getInvitations(for accountEmail: String) -> AnyPublisher<[Invitation], Error> {
        
        Deferred {
            
            Future { promise in
                
                let invitationsRef = self.db.collection(self.invitationsPath).whereField("email", isEqualTo: accountEmail)
                
                invitationsRef.getDocuments { (querySnapshot, error) in
                    
                    if let error = error {
                        promise(.failure(error))
                    } else if let documents = querySnapshot?.documents {
                        
                        var accountInvitationsArray: [Invitation] = []
                        
                        for document in documents {
                            let id = document.documentID
                            let email = document.data()[InvitationKeys.email.rawValue] as? String ?? ""
                            let groupId = document.data()[InvitationKeys.groupId.rawValue] as? String ?? ""
                            let groupName = document.data()[InvitationKeys.groupName.rawValue] as? String ?? ""
                            accountInvitationsArray.append(Invitation(id: id, email: email, groupId: groupId, groupName: groupName))
                        }
                        
                        promise(.success(accountInvitationsArray))
                        
                    } else {
                        promise(.failure(CustomError.error("No invitations found")))
                    }
                }
            }
        }
        .receive(on: RunLoop.main)
        .eraseToAnyPublisher()
    }
    
    func acceptInvitation(userId: String, groupId: String, invitationId: String) -> AnyPublisher<Void, Error> {
        
        Deferred {
            
            Future { promise in
                
                // Add groupId to user's groups
                self.db.collection(self.usersPath).document(userId).updateData([
                    self.groupsPath: FieldValue.arrayUnion([groupId])
                ]) { error in
                    if let error = error {
                        promise(.failure(error))
                    } else {
                        
                        // Add userId to members list of the group
                        self.db.collection(self.groupsPath).document(groupId).updateData([
                            self.membersPath: FieldValue.arrayUnion([userId])
                        ]) { error in
                            if let error = error {
                                promise(.failure(error))
                            } else {
                                
                                // Remove invitation from invitations collection
                                self.db.collection(self.invitationsPath).document(invitationId).delete() { error in
                                    if let error = error {
                                        promise(.failure(error))
                                    } else {
                                        
                                        // Only after all these processes finish successfully
                                        promise(.success(()))
                                    }
                                }
                            }
                        }
                    }
                    
                }
            }
        }
        .receive(on: RunLoop.main)
        .eraseToAnyPublisher()
    }
    
    func removeInvitation(_ invitationId: String) -> AnyPublisher<Void, Error> {
        
        Deferred {
            
            Future { promise in
                
                // Remove invitation from invitations collection
                self.db.collection(self.invitationsPath).document(invitationId).delete() { error in
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
    
    func deleteAccount(_ userId: String) async throws {
        
        // Delete user from DB
        try await removeUserFromGroups(userId: userId)
        try await removeUserFromUserCollection(userId)
        
        // Delete user from Auth
        try await Auth.auth().currentUser?.delete()
    }
    
    private func removeUserFromGroups(userId: String) async throws {
        
        let document = try await db.collection(self.usersPath).document(userId).getDocument()
            
        guard document.exists else {
            throw CustomError.error("User not found")
        }
        
        guard let userGroups = document.data()?["groups"] as? [String] else {
            return
        }
        
        for groupId in userGroups {
            
            // Check if the group is empty after removing the user
            let groupData = try await db.collection(self.groupsPath).document(groupId).getDocument().data()
            let groupMembers = groupData?["members"] as? [String]

            if let members = groupMembers {
                if members.count <= 1 {
                    if let groupCars = groupData?["cars"] as? [String] {
                        try await deleteEmptyGroup(groupId: groupId, groupCars: groupCars)
                    } else {
                        // if there is no cars array for this group but there are no members still delete the group
                        try await deleteEmptyGroup(groupId: groupId, groupCars: [])
                    }
                } else {
                    try await removeUserFromCars(userId: userId, userRelatedCars: groupData?["cars"] as? [String] ?? [])

                    try await db.collection(self.groupsPath).document(groupId).updateData([
                        self.membersPath: FieldValue.arrayRemove([userId])
                    ])
                }
            }
            
        }
        
    }
    
    private func removeUserFromCars(userId: String, userRelatedCars: [String]) async throws {
        
        for carId in userRelatedCars {
            
            if try await db.collection(self.carsPath).document(carId).getDocument().get("currentlyUsedById") as? String == userId {
                try await db.collection(self.carsPath).document(carId).updateData([
                    CarKeys.currentlyInUse.rawValue: false,
                    CarKeys.currentlyUsedById.rawValue: "",
                    CarKeys.currentlyUsedByFullName.rawValue: "",
                ])
            }

        }
    }
    
    private func removeUserFromUserCollection(_ userId: String) async throws {
        try await db.collection(self.usersPath).document(userId).delete()
    }
    
    private func deleteEmptyGroup(groupId: String, groupCars: [String]) async throws {
        
        // Delete the cars of the group from cars collection
        for carId in groupCars {
            try await db.collection(self.carsPath).document(carId).delete()
        }
        
        try await db.collection(self.groupsPath).document(groupId).delete()
    }
    
}
