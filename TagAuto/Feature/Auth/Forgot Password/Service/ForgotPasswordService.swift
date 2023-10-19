//
//  ForgotPasswordService.swift
//  TagAuto
//
//  Created by Nir Neuman on 24/07/2023.
//

import Foundation
import Combine
import Firebase

protocol ForgotPasswordService {
    func sendPasswordReset(to email: String) async throws
}

final class ForgotPasswordServiceImpl: ForgotPasswordService {
    
    func sendPasswordReset(to email: String) async throws {
        try await Auth.auth().sendPasswordReset(withEmail: email)
    }
    
}
