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
    func updateCarNote(car: Car, note: String)
    func getAddress(car: Car, geopoint: CLLocationCoordinate2D)
    func getCarNote(car: Car)
    init(service: CarsServiceImpl)
}

final class CarsViewModelImpl: CarsViewModel, ObservableObject {
    
    private var subscriptions = Set<AnyCancellable>()
    private let service: CarsServiceImpl
    private let locationManager = CLLocationManager()
    
    @Published var state: CarsState = .na
    @Published var hasError: Bool = false
    @Published var cars: [Car] = []
    @Published var carAdress: String = ""
    @Published var carNewNote: String = ""
    @Published var isLocationLatest: Bool = false
    @Published var isLoading: Bool = true
    @Published var isLoadingCars: Bool = true
    @Published var isLoadingLocationLatest: Bool = true
    @Published var selectedCar: Car?
    @Published var locationUpdated: Bool = false
    @Published var currentLocationFocus: CLLocation?
    
    
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
                    self?.isLoadingCars = false
                    self?.state = .failed(error: error)
                default: break
                }
            } receiveValue: { [weak self] cars in
                self?.cars = cars
                self?.isLoadingCars = false
                self?.state = .successful
            }
            .store(in: &subscriptions)
    }
    
    func updateCarLocation(_ car: Car) {
        
        self.isLoading = true
        
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
                } receiveValue: { [weak self] geoPoint in
                    self?.isLoading = false
                    self?.state = .successful
                    self?.currentLocationFocus = currentLocation
                    self?.getIsLocationLatest(for: car)
                    self?.getAddress(car: car, geopoint: CLLocationCoordinate2D(latitude: geoPoint.latitude, longitude: geoPoint.longitude))
                }
                .store(in: &subscriptions)
        } else {
            self.state = .unsuccessful(reason: "Location is not available")
        }
        
    }
    
    func selectCar(_ car: Car?) {
        selectedCar = car
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
                self?.getIsLocationLatest(for: car)
            }
            .store(in: &subscriptions)
    }
    
    func getAddress(car: Car, geopoint: CLLocationCoordinate2D) {

        self.isLoading = true
        self.carAdress = ""
        
        if geopoint.latitude == 0 && geopoint.longitude == 0 {
            self.carAdress = ""
            self.isLoading = false
        } else {
            service.getAddress(carId: car.id, geopoint: geopoint)
                .receive(on: DispatchQueue.main)
                .sink { [weak self] res in
                    switch res {
                    case .failure (let error):
                        self?.isLoading = false
                        self?.state = .failed(error: error)
                    default: break
                    }
                } receiveValue: { [weak self] adress in
                    self?.carAdress = adress
                    self?.isLoading = false
                    self?.state = .successful
                    self?.updateCarAddress(carId: car.id, adress: adress)
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
    
    func getIsLocationLatest(for car: Car) {
        
        self.isLoadingLocationLatest = true
        
        service.getIsLocationLatest(for: car)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] res in
                switch res {
                case .failure (let error):
                    self?.isLoadingLocationLatest = false
                    self?.state = .failed(error: error)
                default: break
                }
            } receiveValue: { [weak self] isLocationLatest in
                self?.isLocationLatest = isLocationLatest
                self?.isLoadingLocationLatest = false
                self?.state = .successful
//                self?.getAddress(car: car, geopoint: <#CLLocationCoordinate2D#>)
            }
            .store(in: &subscriptions)
        
    }
    
    func updateCarAddress(carId: String, adress: String) {
        
        self.isLoading = true
        
        service.updateCarAddress(carId: carId, adress: adress)
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

