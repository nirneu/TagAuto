//
//  GroupsViewModel.swift
//  FindCar
//
//  Created by Nir Neuman on 01/08/2023.
//

import Foundation
import Combine

enum GroupsState {
    case successful
    case failed(error: Error)
    case na
}

protocol GroupsViewModel {
    var groups: [String] { get }
    var state: GroupsState { get }
    var hasError: Bool { get }
    func fetchUserGroups(userId: String)
    init(service: GroupsService)
}

final class GroupsViewModelImpl: GroupsViewModel, ObservableObject {
    
    private var subscriptions = Set<AnyCancellable>()
    private let service: GroupsService
    
    @Published var state: GroupsState = .na
    @Published var groups = [String]()
    @Published var hasError: Bool = false
    
    init(service: GroupsService) {
        self.service = service
        setupErrorSubscription()
    }
    
    func fetchUserGroups(userId: String) {
        service.getGroups(of: userId)
            .sink { [weak self] res in
                
                switch res {
                case .failure (let error):
                    self?.state = .failed(error: error)
                default: break
                }
                
            } receiveValue: { [weak self] groups in
                self?.groups = groups
                self?.state = .successful
            }
            .store(in: &subscriptions)
    }
}

extension GroupsViewModelImpl {
    
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
