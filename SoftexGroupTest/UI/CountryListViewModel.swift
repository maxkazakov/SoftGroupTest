//
//  CountryListViewModel.swift
//  SoftexGroupTest
//
//  Created by Максим Казаков on 15/05/2019.
//  Copyright © 2019 Максим Казаков. All rights reserved.
//

import Kingfisher
import RxSwift


/// Протокол презентера списка стран
protocol CountryListViewModel: class {
    
    /// Загрузить следующую страницу
    func loadNextPage(row: Int)
    
    /// Список стран
    var dataSource: Observable<[CountryCellModel]> { get }
    
    /// Признак — есть ли еще данные для загрузки
    var hasMore: Observable<Bool> { get }
    
    /// Удалить объект
    ///
    /// - Parameter id: индекс объекта
    func delete(idx: Int)
}


class CountryListViewModelImpl: CountryListViewModel {
    
    init(networkService: NetworkService, localStorage: LocalStorage) {
        self.networkService = networkService
        self.localStorage = localStorage
                
        hasMore = Observable.combineLatest(hasMoreServer.asObservable(), hasMoreDB.asObservable()) { $0 || $1 }
        dataSource = items.asObservable()
        
        localStorage.subscribe(subscriber: self)
    }
    
    
    // MARK: -ListPresenter
    let hasMore: Observable<Bool>
    
    let dataSource: Observable<[CountryCellModel]>
    
    func delete(idx: Int) {
        let country = items.value[idx]
        localStorage.delete(id: country.id)
    }
    
    
    func loadNextPage(row: Int) {
        guard hasMoreDB.value || hasMoreServer.value,
            row == (items.value.count - 1) else {
            return
        }
        // Загружаем страницу из БД
        loadPage(sortKey: items.value.last?.sortId)
        
        // Инициируем загрузку с сервера только 1 раз, т.к.
        // пагинация в API отсутствует
        if hasMoreServer.value {
            loadFromServer { [weak self] error in
                self?.hasMoreServer.value = false
                if let error = error {
                    print(error)
                }
            }
        }
    }
    
    // MARK: -Private
    private let pageSize: Int = 20
    private let networkService: NetworkService
    private let localStorage: LocalStorage
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yyyy HH:mm"
        return formatter
    }()
    private let items: Variable<[CountryCellModel]> = Variable([])
    
    private var isLoadingFromDB: Bool = false
    private var isLoadingFromServer: Bool = false
    
    private var hasMoreServer = Variable<Bool>(true)
    private var hasMoreDB = Variable<Bool>(true)
    
    
    private func onNewPageDidLoad(countries: [Country]) {
        items.value = items.value + countries.map(buildCellModel)
    }
    
    private func onNewDidDataUpdated(countries: [Country]) {
        items.value = countries.map(buildCellModel)
    }
    
    
    private func buildCellModel(country: Country) -> CountryCellModel {
        let time = dateFormatter.string(from: country.time)
        let imageFuture = buildImageFuture(url: country.image)
        
        let item = CountryCellModel(
            id: country.id,
            sortId: country.sortId,
            name: country.name,
            time: time,
            image: imageFuture
        )
        return item
    }
    
    
    private func buildImageFuture(url: URL?) -> Future<UIImage>? {
        guard let url = url else {
            return nil
        }
        let imageFuture = Future<UIImage> { onComplete in
            KingfisherManager.shared.retrieveImage(
                with: ImageResource(downloadURL: url),
                options: nil,
                progressBlock: nil) { image, error, _, _ in
                    onComplete(error, image)
            }
        }
        return imageFuture
    }
    
    
    private func loadPage(sortKey: Int?) {
        guard !isLoadingFromDB else {
            return
        }
        isLoadingFromDB = true
        loadFromDB(fromSortKey: sortKey, pageSize: pageSize + 1) { [weak self] countries in
            guard let strong = self else { return }
            let a = countries.count > strong.pageSize
            strong.hasMoreDB.value = a
            strong.onNewPageDidLoad(countries: countries)
            strong.isLoadingFromDB = false
        }
    }
    
    
    private func loadFromDB(fromSortKey sortKey: Int?, pageSize: Int, completion: @escaping ([Country]) -> Void) {
        let lastSortKey = sortKey ?? -1
        let predicate = NSPredicate(format: "sortId > \(lastSortKey)")
        localStorage.load(predicate: predicate, sortKeyPath: "sortId", count: pageSize, queue: .main, completion: completion)
    }
    
    
    private func loadFromServer(completion: @escaping (Error?) -> Void) {
        guard !isLoadingFromServer else {
            return
        }
        isLoadingFromServer = true
        networkService.loadData(queue: .main) { [weak self] (result: Result<[CountryRemoteEntity], Error>) in
            guard let strong = self else {
                return
            }
            switch result {
            case .success(let countriesRemote):
                let countries = countriesRemote.map { $0.county }
                strong.localStorage.save(items: countries)
                completion(nil)
            case .failure(let error):
                completion(error)
            }
            strong.isLoadingFromServer = false
        }
    }
}


extension CountryListViewModelImpl: LocalStorageSubcriber {
    
    // TODO: Здесь в дальнейшем можно получать список изменений и анимированно применять их.
    /// Слушаем изменения в БД.
    func onDataDidChange() {
        let itemsCount = max(pageSize, items.value.count)
        guard !isLoadingFromDB else {
            return
        }
        isLoadingFromDB = true
        
        loadFromDB(fromSortKey: nil, pageSize: itemsCount + 1) { [weak self] countries in
            guard let strong = self else { return }
            strong.hasMoreDB.value = countries.count >= itemsCount
            strong.onNewDidDataUpdated(countries: countries)
            strong.isLoadingFromDB = false
        }
    }
}
