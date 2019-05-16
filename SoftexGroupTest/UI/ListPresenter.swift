//
//  ListPresenter.swift
//  SoftexGroupTest
//
//  Created by Максим Казаков on 15/05/2019.
//  Copyright © 2019 Максим Казаков. All rights reserved.
//

import Kingfisher


protocol ListPresenter: class {
    func loadData()
    var itemsCount: Int { get }
    func getItem(at row: Int) -> ListItemCellModel
}


class ListPresenterImpl: ListPresenter {
    
    init(view: ListView, networkService: NetworkService) {
        self.networkService = networkService
        self.view = view
    }
    
    func loadData() {
        networkService.loadData(queue: .main) { [weak self] result in
            guard let strong = self else { return }
            switch result {
            case .success(let dtoItems):
                strong.onDataDidLoad(dtoItems: dtoItems)
            default:
                break
            }
        }
    }
    
    // MARK: -ListPresenter
    func getItem(at row: Int) -> ListItemCellModel {
        return items[row]
    }
    
    var itemsCount: Int {
        return items.count
    }
    
    // MARK: -Private
    private let networkService: NetworkService
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yyyy HH:mm"
        return formatter
    }()
    private unowned let view: ListView
    private var items: [ListItemCellModel] = []
    
    private func onDataDidLoad(dtoItems: [CountryDTO]) {
        items = dtoItems.map(buildCellModel)
        view.render()
    }
    
    private func buildCellModel(dto: CountryDTO) -> ListItemCellModel {
        let time = dateFormatter.string(from: dto.time)
        let imageFuture = buildImageFuture(url: dto.image)
        
        let item = ListItemCellModel(
            name: dto.name,
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
}
