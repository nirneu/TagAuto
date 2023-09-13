//
//  AccountViewModel.swift
//  FinnFinds
//
//  Created by Nir Neuman on 17/08/2023.
//

import Foundation
import Combine

enum AccountState {
    case successful
    case failed(error: Error)
    case na
}

protocol AccountViewModel {
    var state: AccountState { get }
    var hasError: Bool { get }
    var isLoading: Bool { get }
    var accountInvitations: [Invitation] { get }
    func fetchAccountInvitations(userEmail: String)
    func acceptInvitation(userId: String, groupId: String, invitationId: String, userEmail: String)
    func removeInvitation(invitationId: String, userEmail: String)
    init(service: AccountServiceImpl)
}

final class AccountViewModelImpl: AccountViewModel, ObservableObject {
    
    @Published var state: AccountState = .na
    @Published var hasError: Bool = false
    @Published var isLoading: Bool = true
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
