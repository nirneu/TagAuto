//
//  RegistrationViewModel.swift
//  FinnFinds
//
//  Created by Nir Neuman on 14/07/2023.
//

import Foundation
import Combine

enum RegistrationState {
    case successful
    case failed(error: Error)
    case na
}

protocol RegistrationViewModel {
    func register()
    var service: RegistrationService { get }
    var state: RegistrationState { get }
    var userDetails: RegistrationDetails { get }
    var hasError: Bool { get }
    init(service: RegistrationService)
}

final class RegistrationViewModelImpl: ObservableObject, RegistrationViewModel {
    
    @Published var state: RegistrationState = .na
    @Published var hasError: Bool = false
    @Published var userDetails: RegistrationDetails = RegistrationDetails.new
    
    private var subscriptions = Set<AnyCancellable>()
    
    let service: RegistrationService
    
    init(service: RegistrationService) {
        self.service = service
        setupErrorSubscription()
    }
    
    func register() {
        
        service.register(with: userDetails)
            .sink { [weak self] res in
                
                switch res {
                case .failure (let error):
                    self?.state = .failed(error: error)
                default: break
                }
                
            } receiveValue: { [weak self] in
                self?.state = .successful
            }
            .store(in: &subscriptions)
    }
}

extension RegistrationViewModelImpl {
    
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

