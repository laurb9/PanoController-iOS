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

class DeviceTableViewController: UITableViewController, CBCentralManagerDelegate {
    var bleManager: CBCentralManager!
    var peripheral: CBPeripheral?
    var panoPeripheral: PanoPeripheral?
    var peripherals: [CBPeripheral] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()

        bleManager = CBCentralManager(delegate: self, queue: DispatchQueue.main)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        peripherals.removeAll(keepingCapacity: false)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return peripherals.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BTPeripheral", for: indexPath) as! DeviceTableViewCell
        let thisPeripheral = peripherals[indexPath.row]
        cell.tag = indexPath.row
        cell.nameView.text = thisPeripheral.name
        cell.connectingView.isHidden = true
        if thisPeripheral.identifier == peripheral?.identifier {
            if peripheral?.state == .connected {
                cell.connectingView.stopAnimating()
                cell.accessoryType = .checkmark
            } else {
                cell.connectingView.startAnimating()
            }
        } else {
            cell.accessoryType = .none
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

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let targetPeripheral = peripherals[indexPath.row]
        if targetPeripheral.state == .connected ||
            targetPeripheral.identifier == peripheral?.identifier {
            // previously connected, disconnect
            bleManager.cancelPeripheralConnection(targetPeripheral)
            peripheral = nil
        } else {
            print("Connecting to \(targetPeripheral.name!) id \(targetPeripheral.identifier)")
            bleManager.stopScan()
            self.peripheral = targetPeripheral
            bleManager.connect(targetPeripheral, options: nil)
            tableView.reloadRows(at: [indexPath], with: .none)
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    // MARK: - BLE 

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            central.scanForPeripherals(withServices: nil, options: nil)
        default:
            print("Bluetooth unavailable")
            peripherals.removeAll(keepingCapacity: false)
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        let capabilities = (advertisementData as NSDictionary)
        if peripheral.name != nil && peripheral.name != "" && peripheral.state == .disconnected &&
            // check if this device wasn't added already
            peripherals.filter({$0.identifier == peripheral.identifier}).count == 0 &&
            // and that we can connect to it
            capabilities.object(forKey: CBAdvertisementDataIsConnectable) as? Bool ?? false,
            let dataServices = capabilities.object(forKey: CBAdvertisementDataServiceUUIDsKey) as? NSArray,
            // We are only looking for devices that have the PanoController Service
            dataServices.contains(PanoPeripheral.PanoControllerService.UUID) {

            print("New peripheral \(peripheral) \(RSSI)")
            print(capabilities.description)
            peripherals.append(peripheral)
            tableView.reloadData()
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("didConnect \(peripheral.name!)")
        panoPeripheral = PanoPeripheral(peripheral)
        tableView.reloadData()
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("didFailToConnect: \(String(describing: error))")
        self.peripheral = nil
        self.panoPeripheral = nil
        central.scanForPeripherals(withServices: nil, options: nil)
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("didDisconnectPeripheral: \(peripheral.name!)")
        self.peripheral = nil
        self.panoPeripheral = nil
        central.scanForPeripherals(withServices: nil, options: nil)
        tableView.reloadData()
    }
}
