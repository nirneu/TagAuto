//
//  SessionService.swift
//  FinnFinds
//
//  Created by Nir Neuman on 14/07/2023.
//

import Foundation
import Combine
import Firebase
import SwiftUI

enum SessionState {
    case loggedIn
    case loggedOut
}

protocol SessionService {
    var state: SessionState { get }
    var userDetails: UserDetails? { get }
    func logout()
}


final class SessionServiceImpl: ObservableObject, SessionService {
    
    @Published var state: SessionState = .loggedOut
    @Published var userDetails: UserDetails?
            
    private var handler: AuthStateDidChangeListenerHandle?
    
    init() {
        setupFirebaseAuthHandler()
    }
    
    func logout() {
        try? Auth.auth().signOut()
    }
    
    deinit {
        if let handler = handler {
            Auth.auth().removeStateDidChangeListener(handler)
        }
    }
}

private extension SessionServiceImpl {
    
    
    /// Setup a listener for changes in the auth state
    func setupFirebaseAuthHandler() {
        handler = Auth.auth().addStateDidChangeListener({ [weak self] res, user in
            guard let self = self else { return }
            if let user = user {
                self.state = .loggedIn
                let uid = user.uid
                let userEmail = user.email ?? ""
                self.handlerRefresh(uid: uid, userEmail: userEmail)
            } else {
                self.state = .loggedOut
                self.userDetails = nil
            }
        })
    }
    
    
    /// Handle changes to the auth state inside the app
    /// - Parameters:
    ///   - uid: The user id
    ///   - userEmail: The user email
    func handlerRefresh(uid: String, userEmail: String) {
        
        if Auth.auth().currentUser != nil {
            
            let db = Firestore.firestore()
            let docRef = db.collection("users").document(uid)
            
            docRef.getDocument { [weak self] (document, error) in
                
                if let self = self {
                    if let document = document, document.exists {
                        guard let dataDescription = document.data(),
                              let firstName = dataDescription[RegistrationKeys.firstName.rawValue] as? String,
                              let lastName = dataDescription[RegistrationKeys.lastName.rawValue] as? String else {
                            return
                        }
                        
                        DispatchQueue.main.async {
                            self.userDetails = UserDetails(userId: uid, userEmail: userEmail, firstName: firstName, lastName: lastName)
                        }
                    }
                }
            }
        }
    }
}

