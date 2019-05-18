//
//  ViewController.swift
//  SoftexGroupTest
//
//  Created by Максим Казаков on 13/05/2019.
//  Copyright © 2019 Максим Казаков. All rights reserved.
//

import UIKit

struct CountryCellModel {
    let id: UUID
    let sortId: Int
    let name: String
    let time: String
    let image: Future<UIImage>?
}


/// Протокол вью списка стран
protocol CountryListView: class {
    /// Отрисовать список
    func render()
}


class CountryListViewController: UITableViewController {
    
    class var identifier: String {
        return String(describing: self)
    }
    
    var presenter: CountryListPresenter!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableFooterView = loadingView
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        presenter.loadNextPage()
    }
    
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return presenter.itemsCount
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ListItemTableViewCell.identifier) as! ListItemTableViewCell
        let model = presenter.getItem(at: indexPath.row)
        cell.setup(model: model)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row == (presenter.itemsCount - 1) {
            presenter.loadNextPage()
        }
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            presenter.delete(idx: indexPath.row)            
        }
    }
    
    // MARK: -Private
    private lazy var loadingView: UIView = {
        let spinner = UIActivityIndicatorView(style: .gray)
        spinner.startAnimating()
        spinner.frame = CGRect(x: CGFloat(0), y: CGFloat(0), width: tableView.bounds.width, height: CGFloat(44))
        return spinner
    }()
}


extension CountryListViewController: CountryListView {
    func render() {
        tableView.reloadData()
        loadingView.isHidden = !presenter.hasMore
    }
}

