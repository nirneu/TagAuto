//
//  CarsViewModel.swift
//  FindCar
//
//  Created by Nir Neuman on 04/08/2023.
//

import Foundation
import Combine

enum CarsState {
    case successful
    case failed(error: Error)
    case na
}

protocol CarsViewModel {
    var state: CarsState { get }
    var hasError: Bool { get }
    var cars: [Car] { get }
    func fetchUserCars(userId: String)
    init(service: CarsService)
}

final class CarsViewModelImpl: CarsViewModel, ObservableObject {
    
    private var subscriptions = Set<AnyCancellable>()
    private let service: CarsService
    
    @Published var state: CarsState = .na
    @Published var hasError: Bool = false
    @Published var cars: [Car] = []
    
    
    init(service: CarsService) {
        self.service = service
        setupErrorSubscription()
    }
    
    func fetchUserCars(userId: String) {
        
        guard !userId.isEmpty else {
            return
        }
        
        service.getCars(of: userId)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] res in
                switch res {
                case .failure (let error):
                    self?.state = .failed(error: error)
                default: break
                }
            } receiveValue: { [weak self] cars in
                self?.cars = cars
                self?.state = .successful
            }
            .store(in: &subscriptions)
    }
    
}

extension CarsViewModelImpl {
    
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

