//
//  CountryModel.swift
//  SoftexGroupTest
//
//  Created by Максим Казаков on 13/05/2019.
//  Copyright © 2019 Максим Казаков. All rights reserved.
//

import Foundation

struct CountryDTO: Codable {
    let id: UUID
    let time: Date
    let name: String
    let image: URL?
    
    enum CodingKeys: String, CodingKey {
        case id = "Id"
        case time = "Time"
        case name = "Name"
        case image = "Image"
    }
}
