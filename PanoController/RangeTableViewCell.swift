//
//  RangeTableViewCell.swift
//  PanoController
//
//  Created by Laurentiu Badea on 8/2/17.
//  Copyright © 2017 Laurentiu Badea. All rights reserved.
//

import UIKit

class RangeTableViewCell: UITableViewCell {
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet weak var valueLabel: UILabel!
    @IBOutlet var slider: UISlider!
    let MULTIPLE = 5

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    // Make the slider use MULTIPLEs
    @IBAction func valueChanged(_ sender: Any) {
        let value = lroundf(slider.value) / MULTIPLE * MULTIPLE
        valueLabel?.text = "\(value)º"
    }
    @IBAction func touchUpInside(_ sender: Any) {
        return valueChanged(sender)
    }
}
