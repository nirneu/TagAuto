//
//  LoginService.swift
//  FinnFinds
//
//  Created by Nir Neuman on 16/07/2023.
//

import Foundation
import Combine
import Firebase
import AuthenticationServices
import CryptoKit

enum LoginWithAppleKeys: String {
    case firstName
    case lastName
    case userEmail
}

protocol LoginService {
    func login(with credentials: LoginCredentials) -> AnyPublisher<Void, Error>
    func loginWithApple(with credential: OAuthCredential, appleIDCredential: ASAuthorizationAppleIDCredential) -> AnyPublisher<Void, Error>
    func randomNonceString(length: Int) -> String
    func sha256(_ input: String) -> String
    func saveUserFcmToken(_ userId: String) 
}

final class LoginServiceImpl: LoginService {
    
    func login(with credentials: LoginCredentials) -> AnyPublisher<Void, Error> {
        
        Deferred {
            
            Future { promise in
                
                Auth.auth()
                    .signIn(withEmail: credentials.email, password: credentials.password) { [weak self] res, err in
                        
                        if let err = err {
                            promise(.failure(err))
                        } else {
                            promise(.success(()))
                            
                            if let uid = res?.user.uid {
                                self?.saveUserFcmToken(uid)
                            }
                            
                        }
                    }
            }
        }
        .receive (on: RunLoop.main)
        .eraseToAnyPublisher()
    }
    
    func loginWithApple(with credential: OAuthCredential, appleIDCredential: ASAuthorizationAppleIDCredential) -> AnyPublisher<Void, Error> {
        
        Deferred {
            
            Future { promise in
                
                Auth.auth().signIn(with: credential) { res, err in
                    
                    if let err = err {
                        promise(.failure(err))
                    } else {
                        
                        if let uid = res?.user.uid {
                            
                            if let givenName = appleIDCredential.fullName?.givenName,
                               let familyName = appleIDCredential.fullName?.familyName,
                               let userEmail = appleIDCredential.email {
                                
                                let values = [LoginWithAppleKeys.firstName.rawValue: givenName,
                                              LoginWithAppleKeys.lastName.rawValue: familyName,
                                              LoginWithAppleKeys.userEmail.rawValue: userEmail] as [String: Any]
                                
                                let db = Firestore.firestore()
                                db.collection("users").document(uid).setData(values) { error in
                                    
                                    if let error = error {
                                        promise(.failure(error))
                                    } else {
                                        promise(.success(()))
                                        
                                    }
                                }
                            }
                            
                            self.saveUserFcmToken(uid)
                            
                        }
                    }
                }
            }
        }
        .receive (on: RunLoop.main)
        .eraseToAnyPublisher()
    }
    
    func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError(
                "Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)"
            )
        }
        
        let charset: [Character] =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        
        let nonce = randomBytes.map { byte in
            // Pick a random character from the set, wrapping around if needed.
            charset[Int(byte) % charset.count]
        }
        
        return String(nonce)
    }
    
    func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
    
    func saveUserFcmToken(_ userId: String) {
        // Get the FCM token form user defaults
        guard let fcmToken = UserDefaults.standard.value(forKey: Constants.FCM_TOKEN) else {
            return
        }
        
        let values = [Constants.FCM_TOKEN: fcmToken] as [String: Any]
        
        let db = Firestore.firestore()
        db.collection("users").document(userId).updateData(values)
        
    }
}
