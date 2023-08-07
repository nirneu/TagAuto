//
//  CarsViewModel.swift
//  FindCar
//
//  Created by Nir Neuman on 04/08/2023.
//

import Foundation
import Combine
import CoreLocation

enum CarsState {
    case successful
    case unsuccessful(reason: String)
    case failed(error: Error)
    case na
}

protocol CarsViewModel {
    var state: CarsState { get }
    var hasError: Bool { get }
    var cars: [Car] { get }
    func fetchUserCars(userId: String)
    func selectCar(_ car: Car?)
    func updateCarLocation(_ car: Car)
    init(service: CarsServiceImpl)
}

final class CarsViewModelImpl: CarsViewModel, ObservableObject {
    
    private var subscriptions = Set<AnyCancellable>()
    private let service: CarsServiceImpl
    private let locationManager = CLLocationManager()
    private var currentLocation: CLLocation?
    
    @Published var state: CarsState = .na
    @Published var hasError: Bool = false
    @Published var cars: [Car] = []
    @Published var isLoading: Bool = true
    @Published var selectedCar: Car?
    
    init(service: CarsServiceImpl) {
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
                    self?.isLoading = false
                    self?.state = .failed(error: error)
                default: break
                }
            } receiveValue: { [weak self] cars in
                self?.cars = cars
                self?.isLoading = false
                self?.state = .successful
            }
            .store(in: &subscriptions)
    }
    
    func updateCarLocation(_ car: Car) {
        
        if let currentLocation = locationManager.location {
            service.updateCarLocation(car, location: currentLocation)
                .receive(on: DispatchQueue.main)
                .sink { [weak self] res in
                    switch res {
                    case .failure (let error):
                        self?.isLoading = false
                        self?.state = .failed(error: error)
                    default: break
                    }
                } receiveValue: { [weak self] _ in
                    self?.state = .successful
                }
                .store(in: &subscriptions)
        } else {
            self.state = .unsuccessful(reason: "Location is not available")
        }
        
    }
    
    func selectCar(_ car: Car?) {
        selectedCar = car
    }
    
}

extension CarsViewModelImpl {
    
    func setupErrorSubscription() {
        $state.map { state -> Bool in
            switch state {
            case .successful, .na:
                return false
            case .unsuccessful:
                return true
            case .failed:
                return true
            }
        }
        .assign(to: &$hasError)
    }
    
}

