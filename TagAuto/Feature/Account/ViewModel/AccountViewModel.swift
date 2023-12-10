//
//  AccountViewModel.swift
//  TagAuto
//
//  Created by Nir Neuman on 17/08/2023.
//

import Foundation
import Combine
import FirebaseAuth
import AuthenticationServices

enum AccountState {
    case successful
    case failed(error: Error)
    case na
}

protocol AccountViewModel {
    var state: AccountState { get }
    var hasError: Bool { get }
    var isLoading: Bool { get }
    var isLoadingDeleteAccount: Bool { get }
    var accountInvitations: [Invitation] { get }
    func fetchAccountInvitations(userEmail: String)
    func acceptInvitation(userId: String, groupId: String, invitationId: String, userEmail: String)
    func removeInvitation(invitationId: String, userEmail: String)
    func deleteAccount(userId: String) async -> Bool 
    init(service: AccountServiceImpl)
}

final class AccountViewModelImpl: AccountViewModel, ObservableObject {
    
    @Published var state: AccountState = .na
    @Published var hasError: Bool = false
    @Published var isLoading: Bool = true
    @Published var isLoadingDeleteAccount: Bool = false
    @Published var accountInvitations: [Invitation] = []
    
    private let service: AccountServiceImpl
    private var subscriptions = Set<AnyCancellable>()
    
    init(service: AccountServiceImpl) {
        self.service = service
        setupErrorSubscription()
    }
    
    func fetchAccountInvitations(userEmail: String) {
                
        guard !userEmail.isEmpty else {
            return
        }
        
        service.getInvitations(for: userEmail)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] res in
                switch res {
                case .failure (let error):
                    self?.isLoading = false
                    self?.state = .failed(error: error)
                default: break
                }
            } receiveValue: { [weak self] invitations in
                self?.accountInvitations = invitations
                self?.isLoading = false
                self?.state = .successful
            }
            .store(in: &subscriptions)
    }
    
    func acceptInvitation(userId: String, groupId: String, invitationId: String, userEmail: String) {
        
        self.isLoading = true
        
        guard !userId.isEmpty, !groupId.isEmpty, !invitationId.isEmpty, !userEmail.isEmpty else {
            return
        }
        
        service.acceptInvitation(userId: userId, groupId: groupId, invitationId: invitationId)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] res in
                switch res {
                case .failure (let error):
                    self?.isLoading = false
                    self?.state = .failed(error: error)
                default: break
                }
            } receiveValue: { [weak self] invitations in
                self?.isLoading = false
                self?.state = .successful
                self?.fetchAccountInvitations(userEmail: userEmail)
            }
            .store(in: &subscriptions)
    }
    
    func removeInvitation(invitationId: String, userEmail: String) {
        
        self.isLoading = true
        
        guard !invitationId.isEmpty, !userEmail.isEmpty else {
            return
        }
        
        service.removeInvitation(invitationId)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] res in
                switch res {
                case .failure (let error):
                    self?.isLoading = false
                    self?.state = .failed(error: error)
                default: break
                }
            } receiveValue: { [weak self] invitations in
                self?.isLoading = false
                self?.state = .successful
                self?.fetchAccountInvitations(userEmail: userEmail)
            }
            .store(in: &subscriptions)
    }
    
    @MainActor
    func deleteAccount(userId: String) async -> Bool {
        
        defer {
            isLoadingDeleteAccount = false
        }
        
        isLoadingDeleteAccount = true
        
        guard let user = Auth.auth().currentUser else { return false }
        guard let lastSignInDate = user.metadata.lastSignInDate else { return false }
        let needsReauth = !lastSignInDate.isWithinPast(minutes: 5)
        
        let needsTokenRevocation = user.providerData.contains { $0.providerID == "apple.com" }
        
        do {

        if needsReauth || needsTokenRevocation {
                let signInWithApple = SignInWithApple()
                let appleIDCredential = try await signInWithApple()

                guard let appleIDToken = appleIDCredential.identityToken else {
                  print("Unable to fetdch identify token.")
                  return false
                }
                guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                  print("Unable to serialise token string from data: \(appleIDToken.debugDescription)")
                  return false
                }

                let nonce = randomNonceString()
                let credential = OAuthProvider.credential(withProviderID: "apple.com",
                                                          idToken: idTokenString,
                                                          rawNonce: nonce)

                if needsReauth {
                  try await user.reauthenticate(with: credential)
                }
                if needsTokenRevocation {
                  guard let authorizationCode = appleIDCredential.authorizationCode else { return false }
                  guard let authCodeString = String(data: authorizationCode, encoding: .utf8) else { return false }

                  try await Auth.auth().revokeToken(withAuthorizationCode: authCodeString)
                }
              }

            try await service.deleteAccount(userId)
            state = .successful
            return true
        } catch {
            state = .failed(error: error)
            return false
        }
        
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
    
}

class SignInWithApple: NSObject, ASAuthorizationControllerDelegate {

  private var continuation : CheckedContinuation<ASAuthorizationAppleIDCredential, Error>?

  func callAsFunction() async throws -> ASAuthorizationAppleIDCredential {
    return try await withCheckedThrowingContinuation { continuation in
      self.continuation = continuation
      let appleIDProvider = ASAuthorizationAppleIDProvider()
      let request = appleIDProvider.createRequest()
      request.requestedScopes = [.fullName, .email]

      let authorizationController = ASAuthorizationController(authorizationRequests: [request])
      authorizationController.delegate = self
      authorizationController.performRequests()
    }
  }

  func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
    if case let appleIDCredential as ASAuthorizationAppleIDCredential = authorization.credential {
      continuation?.resume(returning: appleIDCredential)
    }
  }

  func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
    continuation?.resume(throwing: error)
  }
}

extension Date {
  func isWithinPast(minutes: Int) -> Bool {
    let now = Date.now
    let timeAgo = Date.now.addingTimeInterval(-1 * TimeInterval(60 * minutes))
    let range = timeAgo...now
    return range.contains(self)
  }
}

extension AccountViewModelImpl {
    
    func setupErrorSubscription() {
        $state.map { state -> Bool in
            switch state {
            case .successful, .na:
                return false
            case .failed:
                return true
            }
        }
        .assign(to: &$hasError)
    }
    
}
