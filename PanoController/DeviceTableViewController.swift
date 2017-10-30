//
//  DeviceTableViewController.swift
//  PanoController
//
//  Created by Laurentiu Badea on 8/6/17.
//  Copyright © 2017 Laurentiu Badea.
//
//  This file may be redistributed under the terms of the MIT license.
//  A copy of this license has been included with this distribution in the file LICENSE.
//

import CoreBluetooth
import UIKit

protocol DeviceTableViewControllerDelegate {
    func deviceTableViewController(_ deviceTableViewController: DeviceTableViewController, didConnect panoPeripheral: PanoPeripheral)
    func deviceTableViewController(_ deviceTableViewController: DeviceTableViewController, didDisconnect panoPeripheral: PanoPeripheral)
}

class DeviceTableViewController: UITableViewController {
    var bleManager: BLEManager!
    var delegate: DeviceTableViewControllerDelegate?
    @IBOutlet weak var navTitle: UINavigationItem!

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        print("DeviceTableViewControler: \(String(describing: bleManager))")
        bleManager.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return bleManager.peripherals.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BTPeripheral", for: indexPath) as! DeviceTableViewCell
        let thisPeripheral = bleManager.peripherals[indexPath.row]
        cell.tag = indexPath.row
        cell.connectingView.isHidden = true
        cell.nameView.text = "\(thisPeripheral.name ?? "(no name)")\n\(thisPeripheral.identifier)"
        if bleManager.isConnecting(to: thisPeripheral){
            cell.connectingView.startAnimating()
            cell.nameView.text! += "\n(connecting)"
        } else if bleManager.isConnected(to: thisPeripheral){
            cell.connectingView.stopAnimating()
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let targetPeripheral = bleManager.peripherals[indexPath.row]
        if bleManager.isConnected(to: targetPeripheral) {
            // previously connected, disconnect
            bleManager.disconnect()
        } else {
            print("Connecting to \(targetPeripheral.name!) id \(targetPeripheral.identifier)")
            bleManager.connect(targetPeripheral)
            tableView.reloadRows(at: [indexPath], with: .none)
        }
    }

    // MARK: - Navigation
}

// MARK: - BLEManagerDelegate

extension DeviceTableViewController : BLEManagerDelegate {
    func bleManager(_ ble: BLEManager, didDiscover peripheral: CBPeripheral) {
        tableView.reloadData()
    }

    func bleManager(_ ble: BLEManager, didConnect panoPeripheral: PanoPeripheral) {
        delegate?.deviceTableViewController(self, didConnect: panoPeripheral)
        tableView.reloadData()
        performSegue(withIdentifier: "back", sender: self)
    }

    func bleManager(_ ble: BLEManager, didDisconnect panoPeripheral: PanoPeripheral) {
        delegate?.deviceTableViewController(self, didDisconnect: panoPeripheral)
        tableView.reloadData()
    }

    func bleManager(_ ble: BLEManager, didReceiveLine line: String) {
    }
}
