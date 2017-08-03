//
//  SelectTableViewCell.swift
//  PanoController
//
//  Created by Laurentiu Badea on 8/2/17.
//  Copyright © 2017 Laurentiu Badea. All rights reserved.
//

import UIKit

class SelectTableViewCell: UITableViewCell {
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var valueLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
