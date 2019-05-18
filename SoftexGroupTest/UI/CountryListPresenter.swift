//
//  ListPresenter.swift
//  SoftexGroupTest
//
//  Created by Максим Казаков on 15/05/2019.
//  Copyright © 2019 Максим Казаков. All rights reserved.
//

import Kingfisher


protocol CountryListPresenter: class {
    /// Загрузить следующую страницу
    func loadNextPage()
    
    /// Количество моделей
    var itemsCount: Int { get }
    
    /// Получить модель ячейки по индексу
    ///
    /// - Parameter row: индекс
    /// - Returns: модель ячейки
    func getItem(at row: Int) -> CountryCellModel
    
    /// Признак — есть ли еще данные для загрузки
    var hasMore: Bool { get }
    
    /// Удалить объект
    ///
    /// - Parameter id: индекс объекта
    func delete(idx: Int)
}


class CountryListPresenterImpl: CountryListPresenter {
    
    init(view: CountryListView, networkService: NetworkService, localStorage: LocalStorage) {
        self.networkService = networkService
        self.localStorage = localStorage
        self.view = view
        
        localStorage.subscribe(subscriber: self)
    }
    
    
    // MARK: -ListPresenter
    var hasMore: Bool {
        return hasMoreServer || hasMoreDB
    }
    
    
    func getItem(at row: Int) -> CountryCellModel {
        return items[row]
    }
    
    
    var itemsCount: Int {
        return items.count
    }
    
    
    func delete(idx: Int) {
        let country = items[idx]
        localStorage.delete(id: country.id)
    }
    
    
    func loadNextPage() {
        guard hasMore else {
            return
        }
        // Загружаем страницу из БД
        loadPage(sortKey: items.last?.sortId)
        
        // Инициируем загрузку с сервера только 1 раз, т.к.
        // пагинация в API отсутствует
        if hasMoreServer {
            hasMoreServer = false
            loadFromServer { error in
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
    private unowned let view: CountryListView
    private var items: [CountryCellModel] = []
    private var isLoadingFromDB: Bool = false
    
    private var hasMoreServer: Bool = true
    private var hasMoreDB: Bool = true
    
    
    private func onNewPageDidLoad(countries: [Country]) {
        items = items + countries.map(buildCellModel)
        view.render()
    }
    
    private func onNewDidDataUpdated(countries: [Country]) {
        items = countries.map(buildCellModel)
        view.render()
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
            strong.hasMoreDB = countries.count > strong.pageSize
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
}


extension CountryListPresenterImpl: LocalStorageSubcriber {
    func onDataDidChange() {
        let itemsCount = max(pageSize, items.count)
        guard !isLoadingFromDB else {
            return
        }
        isLoadingFromDB = true
        
        loadFromDB(fromSortKey: nil, pageSize: itemsCount + 1) { [weak self] countries in
            guard let strong = self else { return }
            strong.hasMoreDB = countries.count >= itemsCount
            strong.onNewDidDataUpdated(countries: countries)
            strong.isLoadingFromDB = false
        }
    }
}
