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
    var currentCarInfo: Car { get }
    func fetchUserCars(userId: String, newLocation: CLLocation?)
    func selectCar(_ car: Car?)
    func updateCarLocation(car: Car, newLocation: CLLocation, userId: String)
    func markCarAsUsed(carId: String, userId: String, userFullName: String)
    func updateCarNote(car: Car, note: String)
    func getAddress(carId: String, geopoint: CLLocationCoordinate2D)
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
    @Published var currentCarInfo: Car = Car.new
    @Published var carAdress: String = ""
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
    
    func fetchUserCars(userId: String, newLocation: CLLocation? = nil) {
        
        guard !userId.isEmpty else {
            return
        }
                
        self.isLoadingCars = true
        
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
                DispatchQueue.main.async {
                    self?.cars = cars
                    if newLocation != nil {
                        if let location = newLocation {
                            self?.currentLocationFocus = location
                        }
                    }
                    self?.isLoadingCars = false
                    self?.state = .successful
                }
            }
            .store(in: &subscriptions)
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
//                self?.isLoading = false
                self?.state = .successful
                self?.fetchUserCars(userId: userId, newLocation: newLocation)
                self?.selectCar(car)
                self?.getAddress(carId: car.id, geopoint: CLLocationCoordinate2D(latitude: geoPoint.latitude, longitude: geoPoint.longitude))
            }
            .store(in: &subscriptions)
        
    }
    
    func selectCar(_ car: Car?) {
        self.selectedCar = car
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

        self.carAdress = ""
        
        if geopoint.latitude == 0 && geopoint.longitude == 0 {
            self.carAdress = ""
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
                } receiveValue: { [weak self] adress in
                    self?.carAdress = adress
                    self?.isLoading = false
                    self?.state = .successful
                    self?.updateCarAddress(carId: carId, adress: adress)
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
    
    func updateCarAddress(carId: String, adress: String) {
                
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
                self?.state = .successful
                self?.getCar(carId: carId)
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

