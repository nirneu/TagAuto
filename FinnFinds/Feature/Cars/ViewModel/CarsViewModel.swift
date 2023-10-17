//
//  CarsViewModel.swift
//  FinnFinds
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
    var carAddress: String { get }
    var carNewNote: String { get }
    var isLoading: Bool { get }
    var isLoadingCars: Bool { get }
    var selectedCar: Car? { get }
    var locationUpdated: Bool { get }
    var currentLocationFocus: CLLocation? { get }
    func fetchUserCars(userId: String, newLocation: CLLocation?)
    func getCar(carId: String)
    func selectCar(_ car: Car?)
    func updateCarLocation(car: Car, newLocation: CLLocation, userId: String)
    func markCarAsUsed(carId: String, userId: String, userFullName: String)
    func updateCarNote(car: Car, note: String)
    func getAddress(carId: String, geopoint: CLLocationCoordinate2D)
    func getCarNote(car: Car)
    func updateCarAddress(carId: String, address: String)
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
    @Published var carAddress: String = ""
    @Published var carNewNote: String = ""
    @Published var isLoading: Bool = true
    @Published var isLoadingCars: Bool = true
    @Published var selectedCar: Car?
    @Published var locationUpdated: Bool = false
    @Published var currentLocationFocus: CLLocation?

    init(service: CarsServiceImpl) {
        self.service = service
        setupErrorSubscription()
    }
    
//    func fetchUserCars(userId: String, newLocation: CLLocation? = nil) {
//        
//        guard !userId.isEmpty else {
//            return
//        }
//                
//        self.isLoadingCars = true
//        
//        service.getCars(of: userId)
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] res in
//                switch res {
//                case .failure (let error):
//                    self?.isLoadingCars = false
//                    self?.state = .failed(error: error)
//                default: break
//                }
//            } receiveValue: { [weak self] cars in
//                DispatchQueue.main.async {
//                    self?.cars = cars
//                    if newLocation != nil {
//                        if let location = newLocation {
//                            self?.currentLocationFocus = location
//                        }
//                    }
//                    self?.isLoadingCars = false
//                    self?.state = .successful
//                }
//            }
//            .store(in: &subscriptions)
//    }
    
    func fetchUserCars(userId: String, newLocation: CLLocation? = nil) {
        guard !userId.isEmpty else {
            return
        }
        
        self.isLoadingCars = true
        
        Task {
            do {
                let cars = try await service.getCars(of: userId)
                DispatchQueue.main.async {
                    self.cars = cars
                    
                    if let newLocation = newLocation {
                        self.currentLocationFocus = newLocation
                    }
                    
                    self.isLoadingCars = false
                    self.state = .successful
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoadingCars = false
                    self.state = .failed(error: error)
                }
            }
        }
    }

    
    func getCar(carId: String) {
        self.isLoading = true
        self.carNewNote = ""
        
        service.getCar(carId: carId)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] res in
                switch res {
                case .failure (let error):
                    self?.isLoading = false
                    self?.state = .failed(error: error)
                    self?.currentCarInfo = Car.new
                default: break
                }
            } receiveValue: { [weak self] car in
                self?.state = .successful
                self?.currentCarInfo = car
                self?.isLoading = false
            }
            .store(in: &subscriptions)
    }
    
    // updateCarLocation -> getAddress -> updateCarAddress -> getCar -> Finish isLoading and show data for user
    func updateCarLocation(car: Car, newLocation: CLLocation, userId: String) {
        
        self.isLoading = true
    
        service.updateCarLocation(car, location: newLocation)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] res in
                switch res {
                case .failure (let error):
                    self?.isLoading = false
                    self?.state = .failed(error: error)
                default: break
                }
            } receiveValue: { [weak self] geoPoint in
                self?.state = .successful
                self?.fetchUserCars(userId: userId, newLocation: newLocation)
                self?.selectCar(car)
                self?.getAddress(carId: car.id, geopoint: CLLocationCoordinate2D(latitude: geoPoint.latitude, longitude: geoPoint.longitude))
            }
            .store(in: &subscriptions)
        
    }
    
    func selectCar(_ car: Car?) {
        self.selectedCar = car
        if let car = car {
            self.getCar(carId: car.id)
        }
    }
    
    func markCarAsUsed(carId: String, userId: String, userFullName: String) {
        self.isLoading = true
        
        service.markCarAsUsed(carId: carId, userId: userId, userFullName: userFullName)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] res in
                switch res {
                case .failure (let error):
                    self?.isLoading = false
                    self?.state = .failed(error: error)
                default: break
                }
            } receiveValue: { [weak self] _ in
                self?.isLoading = false
                self?.state = .successful
                self?.fetchUserCars(userId: userId)
                self?.getCar(carId: carId)
            }
            .store(in: &subscriptions)
    }

    func updateCarNote(car: Car, note: String) {
        
        self.isLoading = true
        
        service.updateCarNote(car, note: note)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] res in
                switch res {
                case .failure (let error):
                    self?.isLoading = false
                    self?.state = .failed(error: error)
                default: break
                }
            } receiveValue: { [weak self] newNote in
                self?.carNewNote = newNote
                self?.isLoading = false
                self?.state = .successful
                self?.getCarNote(car: car)
            }
            .store(in: &subscriptions)
    }
    
    func getAddress(carId: String, geopoint: CLLocationCoordinate2D) {

        self.carAddress = ""
        
        if geopoint.latitude == 0 && geopoint.longitude == 0 {
            self.carAddress = ""
            self.isLoading = false
        } else {
            service.getAddress(carId: carId, geopoint: geopoint)
                .receive(on: DispatchQueue.main)
                .sink { [weak self] res in
                    switch res {
                    case .failure (let error):
                        self?.isLoading = false
                        self?.state = .failed(error: error)
                    default: break
                    }
                } receiveValue: { [weak self] address in
                    self?.carAddress = address
                    self?.isLoading = false
                    self?.state = .successful
                    self?.updateCarAddress(carId: carId, address: address)
                }
                .store(in: &subscriptions)
        }
        
    }
    
    func getCarNote(car: Car) {
        
        self.isLoading = true
        self.carNewNote = ""
        
        service.getCarNote(car)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] res in
                switch res {
                case .failure (let error):
                    self?.isLoading = false
                    self?.state = .failed(error: error)
                default: break
                }
            } receiveValue: { [weak self] carNote in
                self?.carNewNote = carNote
                self?.isLoading = false
                self?.state = .successful
            }
            .store(in: &subscriptions)
        
    }
    
    func updateCarAddress(carId: String, address: String) {
                
        service.updateCarAddress(carId: carId, address: address)
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
                self?.getCar(carId: carId)
            }
            .store(in: &subscriptions)
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
                self?.fetchUserCars(userId: userId)
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

