//
//  ListPresenter.swift
//  SoftexGroupTest
//
//  Created by Максим Казаков on 15/05/2019.
//  Copyright © 2019 Максим Казаков. All rights reserved.
//

import Kingfisher


protocol ListPresenter: class {
    /// Загрузить следующую страницу
    func loadNextPage()
    
    /// Количество моделей
    var itemsCount: Int { get }
    
    /// Получить модель ячейки по индексу
    ///
    /// - Parameter row: индекс
    /// - Returns: модель ячейки
    func getItem(at row: Int) -> ListItemCellModel
    
    /// Признак — есть ли еще данные для загрузки
    var hasMore: Bool { get }
}


class ListPresenterImpl: ListPresenter {
    
    init(view: ListView, countryListService: CountryListService) {
        self.countryListService = countryListService
        self.view = view
        countryListService.subscribe(subcriber: self)
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
            countryListService.loadFromServer { error in
                if let error = error {
                    print(error)
                }
            }
        }
    }
    
    // MARK: -ListPresenter
    var hasMore: Bool {
        return hasMoreServer || hasMoreDB
    }
    
    func getItem(at row: Int) -> ListItemCellModel {
        return items[row]
    }
    
    var itemsCount: Int {
        return items.count
    }
    
    // MARK: -Private
    private let pageSize: Int = 20
    private let countryListService: CountryListService
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yyyy HH:mm"
        return formatter
    }()
    private unowned let view: ListView
    private var items: [ListItemCellModel] = []
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
    
    
    private func buildCellModel(country: Country) -> ListItemCellModel {
        let time = dateFormatter.string(from: country.time)
        let imageFuture = buildImageFuture(url: country.image)
        
        let item = ListItemCellModel(
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
        countryListService.getCountries(fromSortKey: sortKey, pageSize: pageSize + 1) { [weak self] countries in
            guard let strong = self else { return }
            strong.hasMoreDB = countries.count > strong.pageSize
            strong.onNewPageDidLoad(countries: countries)
            strong.isLoadingFromDB = false
        }
    }
}


extension ListPresenterImpl: CountryListServiceSubscriber {
    func onDataDidiChange() {
        let itemsCount = max(pageSize, items.count)
        guard !isLoadingFromDB else {
            return
        }
        isLoadingFromDB = true
        countryListService.getCountries(fromSortKey: nil, pageSize: itemsCount + 1) { [weak self] countries in
            guard let strong = self else { return }
            strong.hasMoreDB = countries.count >= itemsCount
            strong.onNewDidDataUpdated(countries: countries)
            strong.isLoadingFromDB = false
        }
    }
}
