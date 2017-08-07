//
//  ToggleTableViewCell.swift
//  PanoController
//
//  Created by Laurentiu Badea on 8/2/17.
//  Copyright © 2017 Laurentiu Badea.
//
//  This file may be redistributed under the terms of the MIT license.
//  A copy of this license has been included with this distribution in the file LICENSE.
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
