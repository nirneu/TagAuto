//
//  CarsViewModel.swift
//  TagAuto
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
    var currentCarInfo: Car { get }
    var isLoading: Bool { get }
    var isLoadingCars: Bool { get }
    var selectedCar: Car? { get }
    var locationUpdated: Bool { get }
    var currentLocationFocus: CLLocation? { get }
    func fetchUserCars(userId: String, newLocation: CLLocation?) async
    func getCar(carId: String) async
    func selectCar(_ car: Car?) async
    func updateCarLocation(car: Car, newLocation: CLLocation, userId: String) async
    func markCarAsUsed(carId: String, userId: String, userFullName: String) async
    func updateCarNote(carId: String, note: String) async
    func deleteCar(groupId: String, car: Car, userId: String)
    init(service: CarsServiceImpl)
}

final class CarsViewModelImpl: CarsViewModel, ObservableObject {
    
    private var subscriptions = Set<AnyCancellable>()
    private let service: CarsServiceImpl
    
    @Published var state: CarsState = .na
    @Published var hasError: Bool = false
    @Published var cars: [Car] = []
    @Published var currentCarInfo: Car = Car.new
    @Published var isLoading: Bool = true
    @Published var isLoadingCars: Bool = true
    @Published var selectedCar: Car?
    @Published var locationUpdated: Bool = false
    @Published var currentLocationFocus: CLLocation?

    init(service: CarsServiceImpl) {
        self.service = service
        setupErrorSubscription()
    }
    
    @MainActor
    func fetchUserCars(userId: String, newLocation: CLLocation? = nil) async {
        guard !userId.isEmpty else {
            return
        }
        
        self.isLoadingCars = true
        
        do {
            let cars = try await service.getCars(of: userId)
            self.cars = cars
            
            if let newLocation = newLocation {
                self.currentLocationFocus = newLocation
            }
            
            self.isLoadingCars = false
            self.state = .successful
        } catch {
            self.isLoadingCars = false
            self.state = .failed(error: error)
        }
    }
    
    @MainActor
    func getCar(carId: String) async {
        
        self.isLoading = true
        
        do {
            let car = try await service.getCar(carId: carId)
            self.state = .successful
            self.currentCarInfo = car
            self.isLoading = false
            
        } catch {
            self.isLoading = false
            self.state = .failed(error: error)
            self.currentCarInfo = Car.new
        }
    }
    
    @MainActor
    func updateCarLocation(car: Car, newLocation: CLLocation, userId: String) async {
        self.isLoading = true
        
        do {
            let geoPoint = try await service.updateCarLocation(car, location: newLocation)
            
            self.state = .successful
            
            await self.fetchUserCars(userId: userId, newLocation: newLocation)
            await self.selectCar(car)
            
            let address = try await service.getAddress(carId: car.id, geopoint: CLLocationCoordinate2D(latitude: geoPoint.latitude, longitude: geoPoint.longitude))
            try await service.updateCarAddress(carId: car.id, address: address)
            await self.getCar(carId: car.id)
            
            self.isLoading = false
            
        } catch {
            // Handle the error
            self.isLoading = false
            self.state = .failed(error: error)
            
        }
    }
    
    @MainActor
    func selectCar(_ car: Car?) async {
        self.selectedCar = car
        
        if let car = car {
            await self.getCar(carId: car.id)
        }
    }
    
    @MainActor
    func markCarAsUsed(carId: String, userId: String, userFullName: String) async {
        self.isLoading = true
    
        do {
            try await service.markCarAsUsed(carId: carId, userId: userId, userFullName: userFullName)
            
            self.isLoading = false
            self.state = .successful
            
            await self.fetchUserCars(userId: userId)
    
            // Use getCar function to update car information
            await getCar(carId: carId)
        } catch {
            self.isLoading = false
            self.state = .failed(error: error)
        }
    }
    
    @MainActor
        func updateCarNote(carId: String, note: String) async {
            guard !carId.isEmpty else {
                self.state = .unsuccessful(reason: "Invalid car ID.")
                return
            }
            
            self.isLoading = true

            do {
                try await service.updateCarNote(carId: carId, note: note)
                
                // Use getCar function to update car information
                await getCar(carId: carId)
                
                self.isLoading = false
                self.state = .successful
            } catch {
                self.isLoading = false
                self.state = .failed(error: error)
            }
        }
    
    func deleteCar(groupId: String, car: Car, userId: String) {
        service.deleteCar(groupId, car: car)
            .sink { [weak self] res in
                switch res {
                case .failure(let error):
                    self?.state = .failed(error: error)
                default: break
                }
            } receiveValue: { [weak self] _ in
                self?.state = .successful
                if let self = self {
                    Task {
                        await self.fetchUserCars(userId: userId)
                    }
                }
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
            case .unsuccessful:
                return true
            case .failed:
                return true
            }
        }
        .assign(to: &$hasError)
    }
    
}
