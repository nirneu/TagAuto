//
//  CustomError.swift
//  TagAuto
//
//  Created by Nir Neuman on 19/10/2023.
//

import Foundation

enum CustomError: Error, LocalizedError {
    case error(String)
    
    var errorDescription: String? {
           switch self {
           case .error(let message):
               return message
           }
       }
}
