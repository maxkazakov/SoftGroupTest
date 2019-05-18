//
//  CounrtyEntity.swift
//  SoftexGroupTest
//
//  Created by Максим Казаков on 18/05/2019.
//  Copyright © 2019 Максим Казаков. All rights reserved.
//

import RealmSwift

class CountryEntity: Object {
    @objc dynamic var sortId: Int = -1
    @objc dynamic var id: String = ""
    @objc dynamic var time: Date = Date()
    @objc dynamic var name: String = ""
    @objc dynamic var imageUrl: String? = nil
    
    var county: Country {
        return Country(
            id: UUID(uuidString: id)!,
            time: time,
            name: name,
            image: imageUrl.flatMap(URL.init(string:)),
            sortId: sortId
        )
    }
    
    func set(id: String) {
        self.id = id
    }
    
    func set(country: Country) {
        self.time = country.time
        self.name = country.name
        self.imageUrl = country.image?.absoluteString
    }
    
    override static func primaryKey() -> String? {
        return "id"
    }
}
