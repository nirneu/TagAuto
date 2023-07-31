//
//  LoginViewModel.swift
//  FindCar
//
//  Created by Nir Neuman on 24/07/2023.
//

import Foundation
import Combine
import AuthenticationServices
import Firebase

enum LoginState {
    case successfull
    case failed(error: Error)
    case na
}

protocol LoginViewModel {
    func login()
    func handleSignInWithAppleRequest(with request: ASAuthorizationAppleIDRequest)
    func handleSignInWithAppleCompletion(with result: Result<ASAuthorization, Error>)
    var service: LoginService { get }
    var state: LoginState { get }
    var credentials: LoginCredentials { get }
    var hasError: Bool { get }
    init(service: LoginService)
}

final class LoginViewModelImpl: LoginViewModel, ObservableObject {
    
    @Published var hasError: Bool = false
    @Published var state: LoginState = .na
    @Published var credentials: LoginCredentials = LoginCredentials.new
    @Published var displayName: String = ""
    
    private var subscriptions = Set<AnyCancellable>()
    
    private var currentNonce: String?
    
    let service: LoginService
    
    init(service: LoginService) {
        self.service = service
        setupErrorSubscription()
    }
    
    func login() {
        
        service.login(with: credentials)
            .sink { [weak self] res in
                
                switch res {
                case .failure(let error):
                    self?.state = .failed(error: error)
                default: break
                }
                
            } receiveValue: { [weak self] in
                self?.state = .successfull
            }
            .store(in: &subscriptions)
    }
    
    func handleSignInWithAppleRequest(with request: ASAuthorizationAppleIDRequest) {
        
        request.requestedScopes = [.fullName, .email]
        
        let nonce = service.randomNonceString(length: 32)
        currentNonce = nonce
        request.nonce = service.sha256(nonce)
    }
    
    func handleSignInWithAppleCompletion(with result: Result<ASAuthorization, Error>) {
        
        if case .failure(let error) = result {
            self.state = .failed(error: error)
        } else if case .success(let success) = result {
            
            if let appleIDCredential = success.credential as? ASAuthorizationAppleIDCredential {
                
                guard let nonce = currentNonce else {
                    fatalError("Invalid state: a login callback was received, but no login request was sent.")
                }
                
                guard let appleIDToken = appleIDCredential.identityToken else {
                    print("Unable to fetdch identify token.")
                    return
                }
                
                guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                    print("Unable to serialise token string from data: \(appleIDToken.debugDescription)")
                    return
                }
                
                let credential = OAuthProvider.credential(withProviderID: "apple.com",
                                                          idToken: idTokenString,
                                                          rawNonce: nonce)
                
                service.loginWithApple(with: credential, appleIDCredential: appleIDCredential)
                    .sink { [weak self] res in
                        
                        switch res {
                        case .failure(let error):
                            self?.state = .failed(error: error)
                        default: break
                        }
                        
                    } receiveValue: { [weak self] in
                        self?.state = .successfull
                    }
                    .store(in: &subscriptions)
                
            }
        }
    }
    
}

private extension LoginViewModelImpl {
    
    func setupErrorSubscription() {
        $state.map { state -> Bool in
            switch state {
            case .successfull, .na:
                return false
            case .failed:
                return true
            }
        }
        .assign(to: &$hasError)
    }
    
}
