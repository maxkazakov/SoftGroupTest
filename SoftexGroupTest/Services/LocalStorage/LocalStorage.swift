//
//  LocalStorage.swift
//  SoftexGroupTest
//
//  Created by Максим Казаков on 13/05/2019.
//  Copyright © 2019 Максим Казаков. All rights reserved.
//

import RealmSwift


protocol LocalStorageSubcriber: class {
    func onDataDidChange()
}

protocol LocalStorage: class {
    
    func save(items: [Country])
    
    func load(predicate: NSPredicate, sortKeyPath: String, count: Int, queue: DispatchQueue, completion: @escaping ([Country]) -> Void)
    
    func subscribe(subscriber: LocalStorageSubcriber)
}


class LocalStorageImpl: LocalStorage {
    
    func subscribe(subscriber: LocalStorageSubcriber) {        
        self.subscriber = subscriber
        subscribe()
    }
    
    
    func load(predicate: NSPredicate, sortKeyPath: String, count: Int, queue: DispatchQueue, completion: @escaping ([Country]) -> Void) {
        performAsync { realm in
            let results = realm.objects(CountryEntity.self).filter(predicate).sorted(byKeyPath: sortKeyPath)
            var countries = [Country]()
            for idx in 0..<(min(results.count, count)) {
                countries.append(results[idx].county)
            }
            queue.async {
                completion(countries)
            }            
        }
    }
    
    
    func save(items: [Country]) {
        performAsync { realm in
            var incrementId = (realm.objects(CountryEntity.self).max(ofProperty: "sortId") as Int?) ?? 0
            try! realm.write {
                let models: [CountryEntity] = items.compactMap {                    
                    if realm.object(ofType: CountryEntity.self, forPrimaryKey: $0.id.uuidString) == nil {
                        let model = CountryEntity()
                        model.sortId = incrementId
                        incrementId += 1
                        model.set(id: $0.id.uuidString)
                        model.set(country: $0)
                        return model
                    } else {
                        return nil
                    }
                }
                realm.add(models)
            }
        }
    }
    
    
    // MARK: -Private
    private weak var subscriber: LocalStorageSubcriber?
    private let realmQueue = DispatchQueue(label: "realmQueue")
    private var realm: Realm!
    private var token: NotificationToken?
    
    
    private func subscribe() {
        performAsync { [weak self] realm in
            guard let strong = self else {
                return
            }
            let results = realm.objects(CountryEntity.self)
            strong.token = results.observe { [weak self] _ in
                self?.subscriber?.onDataDidChange()
            }
        }
    }
    
    
    private func ensureRealm() {
        guard realm == nil else {
            return
        }
        self.realm = try! Realm()
    }
    
    
    private func performAsync(block: @escaping (Realm) -> Void) {
//        realmQueue.async { [weak self] in
//            guard let strong = self else {
//                return
//            }
//            strong.ensureRealm()
//            block(strong.realm)
//        }
        
        ensureRealm()
        block(realm)
    }
}