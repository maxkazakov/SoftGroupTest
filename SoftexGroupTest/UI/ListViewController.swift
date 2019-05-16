//
//  ViewController.swift
//  SoftexGroupTest
//
//  Created by Максим Казаков on 13/05/2019.
//  Copyright © 2019 Максим Казаков. All rights reserved.
//

import UIKit

struct ListItemCellModel {
    let name: String
    let time: String
    let image: Future<UIImage>?
}


protocol ListView: class {
    func render()
}


class ListViewController: UITableViewController {
    
    class var identifier: String {
        return String(describing: self)
    }
    
    var presenter: ListPresenter!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        presenter.loadData()
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
}


extension ListViewController: ListView {
    func render() {
        tableView.reloadData()
    }
}

