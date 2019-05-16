//
//  ListItemTableViewCell.swift
//  SoftexGroupTest
//
//  Created by Максим Казаков on 14/05/2019.
//  Copyright © 2019 Максим Казаков. All rights reserved.
//

import UIKit

class ListItemTableViewCell: UITableViewCell {
    class var identifier: String {
        return String(describing: self)
    }
    
    @IBOutlet weak var imgView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!    
    @IBOutlet weak var timeLabel: UILabel!
        
    @IBOutlet var nameToImageContraint: NSLayoutConstraint!
    @IBOutlet var nameLeadingToSuperviewMarginConstraint: NSLayoutConstraint!
    
    func setup(model: ListItemCellModel) {
        imageFuture?.cancel()
        imageFuture = model.image
        
        if let future = imageFuture {
            future.get { [weak self] image in
                self?.showImageView(image: image)                
            }
        } else {
            hideImageView()
        }
        nameLabel.text = model.name
        timeLabel.text = model.time
    }
    
    // MARK: -Private
    private var imageFuture: Future<UIImage>?
    
    private func hideImageView() {
        imgView.image = nil
        imgView.isHidden = true
        nameLeadingToSuperviewMarginConstraint.isActive = true
        nameToImageContraint.isActive = false
    }
    
    private func showImageView(image: UIImage) {
        imgView.image = image
        imgView.isHidden = false
        nameLeadingToSuperviewMarginConstraint.isActive = false
        nameToImageContraint.isActive = true
    }
}
