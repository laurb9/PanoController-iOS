//
//  ToggleTableViewCell.swift
//  PanoController
//
//  Created by Laurentiu Badea on 8/2/17.
//  Copyright © 2017 Laurentiu Badea. All rights reserved.
//

import UIKit

class ToggleTableViewCell: UITableViewCell {
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var switchView: UISwitch!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
