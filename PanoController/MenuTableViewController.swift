//
//  MenuTableViewController.swift
//  PanoController
//
//  Created by Laurentiu Badea on 7/30/17.
//  Copyright © 2017 Laurentiu Badea. All rights reserved.
//

import UIKit

class MenuTableViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.estimatedRowHeight = 24.0
        tableView.rowHeight = UITableViewAutomaticDimension

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return menus.count
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return menus[section].name
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menus[section].entries.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        let menuItem = menus[indexPath.section].entries[indexPath.row]

        if let listSelector = menuItem as? ListSelector {
            cell = tableView.dequeueReusableCell(withIdentifier: "Select", for: indexPath)
            let selectCell = cell as! SelectTableViewCell
            selectCell.nameLabel?.text = listSelector.name
            selectCell.valueLabel?.text = listSelector.currentOptionName()
            cell.accessoryType = .disclosureIndicator

        } else if let actionItem = menuItem as? ActionItem {
            cell = tableView.dequeueReusableCell(withIdentifier: "Select", for: indexPath)
            let selectCell = cell as! SelectTableViewCell
            selectCell.nameLabel?.text = actionItem.name
            cell.accessoryType = .disclosureIndicator

        } else if let switchControl = menuItem as? Switch {
            cell = tableView.dequeueReusableCell(withIdentifier: "Toggle", for: indexPath)
            let toggleCell = cell as! ToggleTableViewCell
            toggleCell.nameLabel?.text = switchControl.name
            toggleCell.switchView?.isOn = switchControl.currentState

        } else {
            let rangeControl = menuItem as! RangeSelector
            cell = tableView.dequeueReusableCell(withIdentifier: "Range", for: indexPath)
            let rangeCell = cell as! RangeTableViewCell
            rangeCell.nameLabel?.text = rangeControl.name
            rangeCell.valueLabel?.text = "\(Int(rangeControl.current))º"
            rangeCell.slider.maximumValue = Float(rangeControl.max)
            rangeCell.slider.minimumValue = Float(rangeControl.min) as Float
            rangeCell.slider.setValue(Float(rangeControl.current), animated: false)
        }
        return cell
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */


    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showOptions" {
            if let indexPath = tableView.indexPathForSelectedRow {
                let destinationController = segue.destination as! OptionViewController
                destinationController.menuItem = menus[indexPath.section].entries[indexPath.row] as? ListSelector
                destinationController.title = destinationController.menuItem?.name
            }
        }
    }
}
