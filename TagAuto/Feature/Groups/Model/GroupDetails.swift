//
//  Groups.swift
//  TagAuto
//
//  Created by Nir Neuman on 01/08/2023.
//
 
import Foundation

struct GroupDetails {
    var id: String
    var name: String
    var members: [String]
    var cars: [String]
}

extension GroupDetails: Hashable {
    static var mockGroups: [GroupDetails] {
        [GroupDetails(id: "G1", name: "Group1", members: ["U1", "U2", "U3"], cars: ["C1", "C2"]),
         GroupDetails(id: "G2", name: "Group2", members: ["U1", "U4"], cars: ["C3"]),
         GroupDetails(id: "G3", name: "Group3", members: ["U2", "U3", "U4"], cars: ["C4", "C5", "C6"])]
    }
    
    static var new: GroupDetails {
        GroupDetails(id: "", name: "", members: [], cars: [])
    }
}
