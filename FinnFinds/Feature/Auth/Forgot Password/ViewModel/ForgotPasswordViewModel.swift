//
//  ForgotPasswordViewModel.swift
//  FinnFinds
//
//  Created by Nir Neuman on 24/07/2023.
//

import Foundation
import Combine

protocol ForgotPasswordViewModel {
    func sendPasswordReset()
    var service: ForgotPasswordService { get }
    var email: String { get }
    init(service: ForgotPasswordService)
}

final class ForgotPasswordViewModelImpl: ObservableObject, ForgotPasswordViewModel {
    
    @Published var email: String = ""
    
    private var subscriptions = Set<AnyCancellable>()
    
    let service: ForgotPasswordService
    
    init(service: ForgotPasswordService) {
        self.service = service
    }
    
    func sendPasswordReset() {
        
        service.sendPasswordReset(to: email)
            .sink { res in

                switch res {
                case .failure (let error):
                    print("Failed: \(error)")
                default: break
                }

            } receiveValue: { 
                print("Sent Password Reset Request")
            }
            .store(in: &subscriptions)
    }
}
