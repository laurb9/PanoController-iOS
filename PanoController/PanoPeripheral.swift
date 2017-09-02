//
//  PanoPeripheral.swift
//  PanoController
//
//  Created by Laurentiu Badea on 8/12/17.
//  Copyright © 2017 Laurentiu Badea. All rights reserved.
//

import Foundation
import CoreBluetooth

var panoPeripheral: PanoPeripheral?

class PanoPeripheral : NSObject, CBPeripheralDelegate, DictionaryObserver {
    let status: Status
    let config: Config

    static let serviceUUID = CBUUID(string: "2017")
    static let configCharUUID = CBUUID(string: "0001")
    static let statusCharUUID = CBUUID(string: "0002")
    static let cmdCharUUID = CBUUID(string: "0003")
    var statusChar: CBCharacteristic?
    var configChar: CBCharacteristic?
    var cmdChar: CBCharacteristic?

    var peripheral: CBPeripheral?

    init(_ peripheral: CBPeripheral) {
        self.status = Status()
        self.config = Config()
        super.init()
        config.observer = self
        self.peripheral = peripheral
        self.peripheral!.delegate = self
        peripheral.discoverServices(nil)
    }

    // Mark: - Config DictionaryObserver

    func didSet(_ config: Config, index: String, value: Int16) {
        if let characteristic = configChar {
            var data = Data()
            config.serialize(index: index, into: &data)
            print("sending \(data) for \(index) to \(characteristic)")
            peripheral?.writeValue(data, for: characteristic, type: .withResponse)
        }
    }

    // Mark: - Send/Receive operations

    func readStatus() -> Status {
        return status
    }

    func sendConfig() {
        for key in config.keys {
            didSet(config, index: key, value: config[key])
        }
    }

    // Mark: - CBPeripheralDelegate

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        print("Services for \(peripheral.name!)")
        for service in peripheral.services! {
            let thisService = service as CBService
            print("    ", thisService)
            peripheral.discoverCharacteristics(nil, for: thisService)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        print("    Characteristics for \(String(describing: service))")
        for characteristic in service.characteristics! {
            let thisCharacteristic = characteristic as CBCharacteristic
            print("         ", thisCharacteristic)
            if thisCharacteristic.uuid == PanoPeripheral.statusCharUUID {
                statusChar = thisCharacteristic
                peripheral.setNotifyValue(true, for: statusChar!)
                peripheral.readValue(for: statusChar!)
            }
            if thisCharacteristic.uuid == PanoPeripheral.configCharUUID {
                configChar = thisCharacteristic
                sendConfig()
            }
            if thisCharacteristic.uuid == PanoPeripheral.cmdCharUUID {
                cmdChar = thisCharacteristic
            }
            //peripheral.discoverDescriptors(for: thisCharacteristic)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?) {
        print("          Descriptors for \(String(describing: characteristic))")
        for descriptor in characteristic.descriptors! {
            let thisDescriptor = descriptor as CBDescriptor
            print("             ", thisDescriptor)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        print("didUpdateValueFor \(String(describing: characteristic))")
        switch characteristic.uuid {
        case PanoPeripheral.configCharUUID:
            print(characteristic.value!)

        case PanoPeripheral.statusCharUUID:
            print(characteristic.value!)
            status.deserialize(characteristic.value!)
            print(status)

        default:
            print("Received update for unknown characteristic \(String(describing: characteristic))")
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        print("didUpdateNotificationStateFor \(String(describing: characteristic))")
    }
}
