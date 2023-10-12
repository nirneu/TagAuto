//
//  GroupsViewModel.swift
//  FinnFinds
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
    var groupCars: [Car] { get }
    func fetchUserGroups(userId: String)
    func createGroup()
    func deleteGroup(_ groupId: String)
    func addCarToGroup(groupId: String, car: Car)
    func deleteCar(groupId: String, car: Car)
    func sendInvitation(to email: String, for groupId: String, groupName: String)
    func deleteMember(userId: String, groupId: String)
    func fetchGroupCars(groupId: String)
    func getMembers(of groupId: String)
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
    @Published var userListReload: Bool = false
    @Published var carListReload: Bool = false
    @Published var groupCars: [Car] = []
    @Published var isLoadingGroups: Bool = true
    @Published var isLoadingMembers: Bool = true
    @Published var isLoadingCars: Bool = true
    
    init(service: GroupsService) {
        self.service = service
        setupErrorSubscription()
    }
    
    func fetchUserGroups(userId: String) {
        
        guard !userId.isEmpty else {
            return
        }
        
        service.getGroups(of: userId)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] res in
                switch res {
                case .failure (let error):
                    self?.state = .failed(error: error)
                    self?.isLoadingGroups = false
                default: break
                }
            } receiveValue: { [weak self] groups in
                self?.groups = groups
                self?.state = .successful
                self?.isLoadingGroups = false
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
    
    func deleteGroup(_ groupId: String) {
        service.deleteGroup(groupId)
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
        
        self.isLoadingMembers = true
        self.memberDetails = []

        service.fetchUserDetails(for: members)
            .sink { [weak self] res in
                switch res {
                case .failure(let error):
                    self?.state = .failed(error: error)
                    self?.isLoadingMembers = false
                default: break
                }
            } receiveValue: { [weak self] userDetails in
                self?.memberDetails = userDetails
                self?.state = .successful
                self?.isLoadingMembers = false
            }
            .store(in: &subscriptions)
    }
    
    func addCarToGroup(groupId: String, car: Car) {
        service.addCarToGroup(groupId, car: car)
            .sink { [weak self] res in
                switch res {
                case .failure(let error):
                    self?.state = .failed(error: error)
                default: break
                }
            } receiveValue: { [weak self] _ in
                self?.state = .successful
                self?.carListReload = true
            }
            .store(in: &subscriptions)
    }
    
    
    func updateCarDetails(_ car: Car) {
        service.updateCarDetails(car)
            .sink { [weak self] res in
                switch res {
                case .failure(let error):
                    self?.state = .failed(error: error)
                default: break
                }
            } receiveValue: { [weak self] _ in
                self?.state = .successful
                self?.carListReload = true
            }
            .store(in: &subscriptions)
    }
    
    
    func deleteCar(groupId: String, car: Car) {
        service.deleteCar(groupId, car: car)
            .sink { [weak self] res in
                switch res {
                case .failure(let error):
                    self?.state = .failed(error: error)
                default: break
                }
            } receiveValue: { [weak self] _ in
                self?.state = .successful
                self?.carListReload = true
            }
            .store(in: &subscriptions)
    }
    
    func fetchGroupCars(groupId: String) {
        
        self.isLoadingCars = true
        self.groupCars = []

        service.getCars(of: groupId)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] res in
                switch res {
                case .failure(let error):
                    self?.state = .failed(error: error)
                    self?.groupCars = []
                    self?.isLoadingCars = false
                default:
                    break
                }
            } receiveValue: { [weak self] cars in
                self?.groupCars = cars
                self?.state = .successful
                self?.isLoadingCars = false
            }
            .store(in: &subscriptions)
    }
    
    func sendInvitation(to email: String, for groupId: String, groupName: String) {
        service.sendInvitation(to: email, for: groupId, groupName: groupName)
            .sink { [weak self] res in
                switch res {
                case .failure(let error):
                    self?.state = .failed(error: error)
                default: break
                }
            } receiveValue: { [weak self] _ in
                self?.state = .successful
                
                self?.sendNotification(to: email, groupName: groupName)
            }
            .store(in: &subscriptions)
        
    }
    
    func sendNotification(to email: String, groupName: String) {
        service.findUserFCMByEmail(email: email)
            .sink { [weak self] res in
                switch res {
                case .failure(let error):
                    self?.state = .failed(error: error)
                default: break
                }
            } receiveValue: { [weak self] fcmValue in
                self?.state = .successful
                
                // Send notification to the invited user
                PushNotificationManager.sendPushNotification(to: fcmValue, title: "New Group Invitation 🎉", body: "You are invited to the group \"\(groupName)\"", link: "group-invitation")
            }
            .store(in: &subscriptions)

    }
    
    func deleteMember(userId: String, groupId: String) {
        service.deleteMember(userId: userId, groupId: groupId)
            .sink { [weak self] res in
                switch res {
                case .failure(let error):
                    self?.state = .failed(error: error)
                default: break
                }
            } receiveValue: { [weak self] _ in
                self?.state = .successful
                self?.userListReload = true
            }
            .store(in: &subscriptions)
    }
    
    func getMembers(of groupId: String) {
        
        self.isLoadingMembers = true
        
        service.getMembersIds(of: groupId)
            .sink { [weak self] res in
                switch res {
                case .failure(let error):
                    self?.state = .failed(error: error)
                default: break
                }
            } receiveValue: { [weak self] membersIds in
                self?.state = .successful

                // Fetch members details
                self?.fetchUserDetails(for: membersIds)
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
