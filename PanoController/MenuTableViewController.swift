//
//  MenuTableViewController.swift
//  PanoController
//
//  Created by Laurentiu Badea on 7/30/17.
//  Copyright © 2017 Laurentiu Badea.
//
//  This file may be redistributed under the terms of the MIT license.
//  A copy of this license has been included with this distribution in the file LICENSE.
//

import UIKit

class MenuTableViewController: UITableViewController, PanoPeripheralDelegate {
    // FIXME: use global context, this seems unsafe. config should be a singleton probably
    var panoPeripheral: PanoPeripheral?
    var menus: Menu?
    @IBOutlet weak var deviceUILabel: UILabel!
    @IBOutlet weak var panoUIBarButtonItem: UIBarButtonItem!

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.estimatedRowHeight = 24.0
        tableView.rowHeight = UITableViewAutomaticDimension

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        panoPeripheral?.delegate = self
        if let p = panoPeripheral {
            menus = getMenus(p.config)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        print("MenuTableViewControler: \(String(describing: panoPeripheral))")
        panoPeripheral?.delegate = self
        self.deviceUILabel.text = panoPeripheral?.name
        panoUIBarButtonItem.isEnabled = panoPeripheral?.isReady ?? false
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return menus!.count
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return menus![section].name
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (menus![section] as! Menu).count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        let menuItem = menus![indexPath]

        switch menuItem {
        case let listSelector as ListSelector:
            cell = tableView.dequeueReusableCell(withIdentifier: "Select", for: indexPath)
            let selectCell = cell as! SelectTableViewCell
            selectCell.nameLabel?.text = listSelector.name
            selectCell.valueLabel?.text = listSelector.currentOptionName()

        case let switchControl as Switch:
            cell = tableView.dequeueReusableCell(withIdentifier: "Toggle", for: indexPath)
            let toggleCell = cell as! ToggleTableViewCell
            toggleCell.nameLabel?.text = switchControl.name
            toggleCell.switchView?.isOn = switchControl.currentState

        case let rangeControl as RangeSelector:
            cell = tableView.dequeueReusableCell(withIdentifier: "Range", for: indexPath)
            let rangeCell = cell as! RangeTableViewCell
            rangeCell.nameLabel?.text = rangeControl.name
            rangeCell.valueLabel?.text = "\(Int(rangeControl.current))º"
            rangeCell.slider.maximumValue = Float(rangeControl.max)
            rangeCell.slider.minimumValue = Float(rangeControl.min) as Float
            rangeCell.slider.setValue(Float(rangeControl.current), animated: false)
        default:
            cell = UITableViewCell()
            print("Unknown menuItem \(menuItem) at \(indexPath)")
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

    // MARK: - Save Settings

    @IBAction func rangeUpdated(_ sender: UISlider) {
        let switchPosition = sender.convert(CGPoint.zero, to: tableView)
        if let indexPath = tableView.indexPathForRow(at: switchPosition),
            let menuItem = menus![indexPath] as? RangeSelector {
            menuItem.current = Int16(Int(sender.value))
        }
    }

    @IBAction func toggleChanged(_ sender: UISwitch) {
        let switchPosition = sender.convert(CGPoint.zero, to: tableView)
        if let indexPath = tableView.indexPathForRow(at: switchPosition),
            let menuItem = menus![indexPath] as? Switch {
            menuItem.currentState = sender.isOn
        }
    }

    // MARK: - Navigation

    @IBAction func unwindToSettings(sender: UIStoryboardSegue){
        //if let _ = sender.source as? OptionViewController,
        //}
        if let selectedIndexPath = tableView.indexPathForSelectedRow {
            tableView.reloadRows(at: [selectedIndexPath], with: .none)
        }
    }

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destinationController = segue.destination as? OptionViewController,
            let listSelector = sender as? SelectTableViewCell,
            let indexPath = tableView.indexPath(for: listSelector) {
            destinationController.menuItem = menus![indexPath] as? ListSelector
            destinationController.title = destinationController.menuItem?.name
        } else if let panoViewController = segue.destination as? PanoViewController {
            panoViewController.panoPeripheral = panoPeripheral
        }
    }

    // MARK: - PanoPeripheralDelegate

    func panoPeripheralDidConnect(_ panoPeripheral: PanoPeripheral){
        self.deviceUILabel.text = panoPeripheral.name
        panoUIBarButtonItem.isEnabled = true
    }
    func panoPeripheralDidDisconnect(_ panoPeripheral: PanoPeripheral){
        panoUIBarButtonItem.isEnabled = false
        performSegue(withIdentifier: "devices", sender: self)
    }
    func panoPeripheral(_ panoPeripheral: PanoPeripheral, didReceiveStatus status: Status){
        if panoPeripheral.status.running == 1 {
            performSegue(withIdentifier: "pano", sender: self)
        }
    }
}
