//
//  ForgotPasswordViewModel.swift
//  FinnFinds
//
//  Created by Nir Neuman on 24/07/2023.
//

import Foundation
import Combine

protocol ForgotPasswordViewModel {
    func sendPasswordReset() async
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
    
    @MainActor
    func sendPasswordReset() async  {
        do {
            try await service.sendPasswordReset(to: email)            
        } catch {
            print("Failed: \(error)")
        }
    } 
}
