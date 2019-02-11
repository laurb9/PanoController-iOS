//
//  BLEManager.swift
//  PanoController
//
//  Created by Laurentiu Badea on 10/29/17.
//  Copyright © 2017 Laurentiu Badea. All rights reserved.
//

import Foundation
import CoreBluetooth

protocol BLEManagerDelegate {
    // a new (generic) BLE peripheral device advertised itself
    func bleManager(_ ble: BLEManager, didDiscover peripheral: CBPeripheral)
    // connected to a PanoPeripheral device
    func bleManager(_ ble: BLEManager, didConnect panoPeripheral: PanoPeripheral)
    // disconnected from a PanoPeripheral device
    func bleManager(_ ble: BLEManager, didDisconnect panoPeripheral: PanoPeripheral)
    // received a line of text
    func bleManager(_ ble: BLEManager, didReceiveLine line: String)
}

// Maintain a list of available BLE devices matching the PanoPeripheral service
// When connected, create and hold a wrapped PanoPeripheral object
class BLEManager : NSObject {
    private var centralManager: CBCentralManager!
    var peripherals: [CBPeripheral] = []
    var peripheral: CBPeripheral?
    var panoPeripheral: PanoPeripheral?
    var delegate: BLEManagerDelegate?

    override init(){
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: DispatchQueue.main)
    }

    convenience init(delegate: BLEManagerDelegate) {
        self.init()
        self.delegate = delegate
    }

    private var lastPeripheralUUID: String? {
        get { return UserDefaults.standard.object(forKey: "lastPeripheralUUID") as? String }
        set { UserDefaults.standard.set(newValue, forKey: "lastPeripheralUUID") }
    }
    private func isLastPeripheral(_ peripheral: CBPeripheral) -> Bool {
        return peripheral.identifier.uuidString == lastPeripheralUUID
    }
    private func setLastPeripheral(_ peripheral: CBPeripheral){
        lastPeripheralUUID = peripheral.identifier.uuidString
    }

    func disconnect() {
        if let peripheral = peripheral {
            centralManager.cancelPeripheralConnection(peripheral)
        }
    }

    func connect(_ peripheral: CBPeripheral){
        disconnect()
        self.peripheral = peripheral
        centralManager.connect(peripheral, options: nil)
    }

    func isConnecting(to peripheral: CBPeripheral) -> Bool {
        return (self.peripheral == peripheral && panoPeripheral == nil)
    }
    func isConnected(to peripheral: CBPeripheral) -> Bool {
        return (panoPeripheral?.peripheral == peripheral)
    }
}

// MARK: - CentralManagerDelegate

extension BLEManager : CBCentralManagerDelegate {

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("didUpdateState: \(central.state)")
        switch central.state {
        case .poweredOn:
            central.scanForPeripherals(withServices: nil, options: nil)
        default:
            print("Bluetooth unavailable")
            disconnect()
            peripherals.removeAll(keepingCapacity: false)
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        let capabilities = (advertisementData as NSDictionary)
        if peripheral.name != nil &&
            peripheral.name != "" &&
            peripheral.state == .disconnected &&
            // check if this device wasn't added already
            peripherals.filter({$0.identifier == peripheral.identifier}).count == 0 &&
            // and that we can connect to it
            capabilities.object(forKey: CBAdvertisementDataIsConnectable) as? Bool ?? false,
            let dataServices = capabilities.object(forKey: CBAdvertisementDataServiceUUIDsKey) as? NSArray,
            // We are only looking for devices that have the PanoController Service
            dataServices.contains(PanoPeripheral.serviceUUID) {

            print("New: \(peripheral) RSSI=\(RSSI)")
            print(capabilities.description)
            peripherals.append(peripheral)
            delegate?.bleManager(self, didDiscover: peripheral)

            // FIXME: move to delegate
            // Autoconnect to the last peripheral used if seen
            if isLastPeripheral(peripheral) {
                connect(peripheral)
            }
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("didConnect: \(peripheral.name!)")
        setLastPeripheral(peripheral)
        panoPeripheral = PanoPeripheral(peripheral, delegate: self)
        centralManager.stopScan()
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("didDisconnectPeripheral: \(peripheral.name!)")
        if isConnected(to: peripheral) {
            self.peripheral = nil
            delegate?.bleManager(self, didDisconnect: panoPeripheral!)
            self.panoPeripheral = nil
        }
        central.scanForPeripherals(withServices: nil, options: nil)
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("didFailToConnect: \(String(describing: error))")
        self.peripheral = nil
        central.scanForPeripherals(withServices: nil, options: nil)
    }

    // MARK: - CustomStringConvertible

    override var description: String {
        get {
            return "<BLEManager deviceCount=\(peripherals.count) connected=\(peripheral != nil) ready=\(panoPeripheral?.isReady ?? false) name=\(panoPeripheral?.name ?? "")>"
        }
    }
}

// MARK: - PanoPeripheralDelegate

extension BLEManager : PanoPeripheralDelegate {
    func panoPeripheralDidConnect(_ panoPeripheral: PanoPeripheral) {
        delegate?.bleManager(self, didConnect: panoPeripheral)
    }

    func panoPeripheral(_ panoPeripheral: PanoPeripheral, didReceiveLine line: String) {
        delegate?.bleManager(self, didReceiveLine: line)
    }
}
