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
    var groups: [GroupDetails] { get }
    var state: GroupsState { get }
    var hasError: Bool { get }
    var groupDetails: GroupDetails { get }
    var memberDetails: [UserDetails] { get }
    func fetchUserGroups(userId: String)
    func createGroup()
    init(service: GroupsService)
}

final class GroupsViewModelImpl: GroupsViewModel, ObservableObject {
    
    private var subscriptions = Set<AnyCancellable>()
    private let service: GroupsService
    
    @Published var state: GroupsState = .na
    @Published var groups = [GroupDetails]()
    @Published var hasError: Bool = false
    @Published var groupDetails: GroupDetails = GroupDetails.new
    @Published var memberDetails: [UserDetails] = []
    @Published var groupCreated: Bool = false
    
    init(service: GroupsService) {
        self.service = service
        setupErrorSubscription()
    }
    
    func fetchUserGroups(userId: String) {
        service.getGroups(of: userId)
            .receive(on: DispatchQueue.main)
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
    
    func createGroup() {
        service.createGroup(with: groupDetails)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] res in
                switch res {
                case .failure(let error):
                    self?.state = .failed(error: error)
                default: break
                }
            } receiveValue: { [weak self] in
                self?.state = .successful
                self?.groupCreated = true
            }
            .store(in: &subscriptions)
    }
    
    func fetchUserDetails(for members: [String]) {
        service.fetchUserDetails(for: members)
            .sink { [weak self] res in
                
                switch res {
                case .failure(let error):
                    self?.state = .failed(error: error)
                default: break
                }
            } receiveValue: { [weak self] userDetails in
                self?.memberDetails = userDetails
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
