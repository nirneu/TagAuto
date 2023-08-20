//
//  Invitation.swift
//  FindCar
//
//  Created by Nir Neuman on 17/08/2023.
//

import Foundation

struct Invitation: Hashable, Identifiable {
    var id: String
    let email: String
    let groupId: String
    let groupName: String
}