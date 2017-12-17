//
//  CustomCell.swift
//  Curious Blossom
//
//  Created by Spencer Yang on 12/16/17.
//  Copyright © 2017 Seungho Yang. All rights reserved.
//

import UIKit

class CustomCell: UITableViewCell {

    @IBOutlet weak var flowerImageView: UIImageView!
    @IBOutlet weak var flowerNameLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func configureCell(flower: Flower) {
        flowerNameLabel.text = flower.name
        flowerImageView.image = UIImage(data: flower.image!)
    }
}
