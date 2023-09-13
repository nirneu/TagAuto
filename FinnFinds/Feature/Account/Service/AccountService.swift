//
//  AccountService.swift
//  FinnFinds
//
//  Created by Nir Neuman on 17/08/2023.
//

import Foundation
import Combine
import FirebaseFirestore

protocol AccountService {
    func getInvitations(for accountEmail: String) -> AnyPublisher<[Invitation], Error>
    func acceptInvitation(userId: String, groupId: String, invitationId: String) -> AnyPublisher<Void, Error>
    func removeInvitation(_ invitationId: String) -> AnyPublisher<Void, Error>
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
                        promise(.failure(NSError(domain: "No invitations found", code: 404)))
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
    
}
