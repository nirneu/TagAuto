//
//  RegistrationDetails.swift
//  TagAuto
//
//  Created by Nir Neuman on 14/07/2023.
//

import Foundation

struct RegistrationDetails {
    var email: String
    var password: String
    var firstName: String
    var lastName: String
}

extension RegistrationDetails {
    static var new: RegistrationDetails {
        RegistrationDetails(email: "", password: "", firstName: "", lastName: "")
    }
}
