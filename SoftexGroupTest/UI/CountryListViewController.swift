//
//  ViewController.swift
//  SoftexGroupTest
//
//  Created by Максим Казаков on 13/05/2019.
//  Copyright © 2019 Максим Казаков. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

struct CountryCellModel {
    let id: UUID
    let sortId: Int
    let name: String
    let time: String
    let image: Future<UIImage>?
}


class CountryListViewController: UITableViewController {
    
    class var identifier: String {
        return String(describing: self)
    }
    
    var viewModel: CountryListViewModel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableFooterView = loadingView
        tableView.delegate = nil
        tableView.dataSource = nil
        
        bind()
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)                
        viewModel.loadNextPage(row: -1)
    }
    
    
    // MARK: -Private
    private let disposeBag = DisposeBag()
    private lazy var loadingView: UIView = {
        let spinner = UIActivityIndicatorView(style: .gray)
        spinner.startAnimating()
        spinner.frame = CGRect(x: CGFloat(0), y: CGFloat(0), width: tableView.bounds.width, height: CGFloat(44))
        return spinner
    }()
    
    /// Привязка view к viewModel 
    private func bind() {
        viewModel.hasMore.subscribe(
            onNext: { [weak self] hasMore in
                self?.loadingView.isHidden = !hasMore
            }).disposed(by: disposeBag)

        viewModel.dataSource.bind(
            to: tableView.rx.items(
                cellIdentifier: ListItemTableViewCell.identifier,
                cellType: ListItemTableViewCell.self
            )) { row, element, cell in
                cell.setup(model: element)
            }
            .disposed(by: disposeBag)
        
        tableView.rx
            .willDisplayCell
            .subscribe(onNext: { [weak self] cell, indexPath in
                guard let strong = self else {
                    return
                }
                strong.viewModel.loadNextPage(row: indexPath.row)
            })
            .disposed(by: disposeBag)
        
        tableView.rx.itemDeleted
            .subscribe(onNext: { [weak self] indexPath in
                self?.viewModel.delete(idx: indexPath.row)
            }).disposed(by: disposeBag)
    }
}

