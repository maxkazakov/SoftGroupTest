//
//  LocalStorage.swift
//  SoftexGroupTest
//
//  Created by Максим Казаков on 13/05/2019.
//  Copyright © 2019 Максим Казаков. All rights reserved.
//

import RealmSwift


/// Подписчик на изменения в БД
protocol LocalStorageSubcriber: class {
    func onDataDidChange()
}

/// Интерфейс работы с БД
protocol LocalStorage: class {
    
    /// Удалить по объект id
    ///
    /// - Parameter id: первичный ключ объекта
    func delete(id: UUID)
    
    /// Сохранить список стран в БД
    ///
    /// - Parameter items: список стран
    func save(items: [Country])
    
    
    /// Загрузить список стран
    ///
    /// - Parameters:
    ///   - predicate: предикат запроса
    ///   - sortKeyPath: ключ сортировки
    ///   - count: количество загружаемых объектов
    ///   - queue: очередь для вызова completion
    ///   - completion: callback
    func load(predicate: NSPredicate, sortKeyPath: String, count: Int, queue: DispatchQueue, completion: @escaping ([Country]) -> Void)
    
    func subscribe(subscriber: LocalStorageSubcriber)
}


class LocalStorageImpl: LocalStorage {
    
    func subscribe(subscriber: LocalStorageSubcriber) {        
        self.subscriber = subscriber
        subscribe()
    }
    
    
    func delete(id: UUID) {
        performAsync { realm in
            guard let object = realm.object(ofType: CountryEntity.self, forPrimaryKey: id.uuidString) else {
                return
            }
            try! realm.write {
                realm.delete(object)
            }
        }
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
    private var token: NotificationToken?
    
    
    private func subscribe() {
        // Подписываться на realm можно только на потоках с runLoop, для простоты использую main
        let realm = try! Realm()
        let results = realm.objects(CountryEntity.self)
        self.token = results.observe { [weak self] changes in
            switch changes {
            case .initial:
                return
            case .error(let error):
                fatalError("\(error)")
            default:
                self?.subscriber?.onDataDidChange()
            }
        }
    }
    
    
    private func performAsync(block: @escaping (Realm) -> Void) {
        realmQueue.async {
            let realm = try! Realm()
            block(realm)
        }
    }
}
