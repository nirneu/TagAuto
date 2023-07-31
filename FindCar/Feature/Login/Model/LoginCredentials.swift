//
//  LoginCredentials.swift
//  FindCar
//
//  Created by Nir Neuman on 16/07/2023.
//

import Foundation

struct LoginCredentials {
    var email: String
    var password: String 
}

extension LoginCredentials {
    
    static var new: LoginCredentials {
        LoginCredentials(email: "", password: "")
    }
}
