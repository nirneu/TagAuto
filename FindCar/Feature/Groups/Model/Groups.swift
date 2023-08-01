//
//  Groups.swift
//  FindCar
//
//  Created by Nir Neuman on 01/08/2023.
//
 
import Foundation

struct Groups {
    var id: String
    var name: String
    var members: [String]
    var cars: [String]
}

extension Groups {
    static var mockGroups: [Groups] {
        [Groups(id: "G1", name: "Group1", members: ["U1", "U2", "U3"], cars: ["C1", "C2"]),
         Groups(id: "G2", name: "Group2", members: ["U1", "U4"], cars: ["C3"]),
         Groups(id: "G3", name: "Group3", members: ["U2", "U3", "U4"], cars: ["C4", "C5", "C6"])]
    }
}
