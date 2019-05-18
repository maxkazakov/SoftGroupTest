//
//  CountryListService.swift
//  SoftexGroupTest
//
//  Created by Максим Казаков on 17/05/2019.
//  Copyright © 2019 Максим Казаков. All rights reserved.
//

import Foundation


protocol CountryListServiceSubscriber: class {
    func onDataDidiChange()
}


protocol CountryListService: class {
    
    func getCountries(fromSortKey sortKey: Int?, pageSize: Int, completion: @escaping ([Country]) -> Void)
    
    func subscribe(subcriber: CountryListServiceSubscriber)
    
    func loadFromServer(completion: @escaping (Error?) -> Void)
}


class CountryListServiceImpl: CountryListService, LocalStorageSubcriber {
    
    init(localStorage: LocalStorage, networkService: NetworkService) {
        self.localStorage = localStorage
        self.networkService = networkService
    }
    
    
    // MARK: -CountryListService
    func getCountries(fromSortKey sortKey: Int?, pageSize: Int, completion: @escaping ([Country]) -> Void) {
        let lastSortKey = sortKey ?? -1
        let predicate = NSPredicate(format: "sortId > \(lastSortKey)")
        localStorage.load(predicate: predicate, sortKeyPath: "sortId", count: pageSize, queue: .main, completion: completion)
    }
    
    
    func subscribe(subcriber: CountryListServiceSubscriber) {
        self.subscriber = subcriber
        localStorage.subscribe(subscriber: self)
    }
    
    
    func loadFromServer(completion: @escaping (Error?) -> Void) {
        networkService.loadData(queue: .main) { (result: Result<[CountryRemoteEntity], Error>) in
            switch result {
            case .success(let countriesRemote):
                let countries = countriesRemote.map { $0.county }
                self.localStorage.save(items: countries)
                completion(nil)
            case .failure(let error):
                completion(error)
            }
        }
    }
    
    
    // MARK: -LocalStorageSubcriber
    func onDataDidChange() {
        subscriber?.onDataDidiChange()
    }
    
    // MARK: -Private
    private let localStorage: LocalStorage
    private let networkService: NetworkService
    private weak var subscriber: CountryListServiceSubscriber?
}
