//
//  SessionService.swift
//  FindCar
//
//  Created by Nir Neuman on 14/07/2023.
//

import Foundation
import Combine
import Firebase

enum SessionState {
    case loggedIn
    case loggedOut
}

protocol SessionService {
    var state: SessionState { get }
    var userDetails: SessionUserDetails? { get }
    func logout()
}

final class SessionServiceImpl: ObservableObject, SessionService {
    
    @Published var state: SessionState = .loggedOut
    @Published var userDetails: SessionUserDetails?
    
    private var handler: AuthStateDidChangeListenerHandle?
    
    init() {
        setupFirebaseAuthHandler()
    }
    
    func logout() {
        try? Auth.auth().signOut()
    }
}

private extension SessionServiceImpl {
    
    func setupFirebaseAuthHandler() {
        
        handler = Auth.auth().addStateDidChangeListener({ [weak self] res, user in
            guard let self = self else { return }
            self.state = user == nil ? .loggedOut : .loggedIn
            if let uid = user?.uid, let userEmail = user?.email {
                self.handlerRefresh(uid: uid, userEmail: userEmail)
            }
        })
    }
    
    func handlerRefresh(uid: String, userEmail: String) {
        
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
                        self.userDetails = SessionUserDetails(userId: uid, userEmail: userEmail, firstName: firstName, lastName: lastName)
                    }
                }
            }
        }
    }
}

