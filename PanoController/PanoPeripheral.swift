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

    static let uartServiceUUID = CBUUID(string: "6E400001-B5A3-F393-E0A9-E50E24DCCA9E")
    static let uartTxCharUUID = CBUUID(string: "6E400002-B5A3-F393-E0A9-E50E24DCCA9E")
    static let uartRxCharUUID = CBUUID(string: "6E400003-B5A3-F393-E0A9-E50E24DCCA9E")
    static let serviceUUID = CBUUID(string: "2017")
    static let statusCharUUID = CBUUID(string: "0002")
    var statusChar: CBCharacteristic?
    var uartTxChar: CBCharacteristic?
    var uartRxChar: CBCharacteristic?

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
        if let characteristic = uartTxChar {
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
            if service.uuid == PanoPeripheral.serviceUUID,
                thisCharacteristic.uuid == PanoPeripheral.statusCharUUID {
                statusChar = thisCharacteristic
                peripheral.setNotifyValue(true, for: statusChar!)
                peripheral.readValue(for: statusChar!)
            }
            if service.uuid == PanoPeripheral.uartServiceUUID {
                if thisCharacteristic.uuid == PanoPeripheral.uartTxCharUUID {
                    uartTxChar = thisCharacteristic
                    sendConfig()
                }
                if thisCharacteristic.uuid == PanoPeripheral.uartRxCharUUID {
                    uartRxChar = thisCharacteristic
                }
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
        //print("didUpdateValueFor \(String(describing: characteristic))")
        switch characteristic.uuid {
        case PanoPeripheral.uartRxCharUUID:
            print(characteristic.value!)

        case PanoPeripheral.statusCharUUID:
            //print(characteristic.value!)
            status.deserialize(characteristic.value!)
            //print(status)

        default:
            print("Received update for unknown characteristic \(String(describing: characteristic))")
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        print("didUpdateNotificationStateFor \(String(describing: characteristic))")
    }

    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        //print("didWriteValueForCharacteristic \(String(describing: characteristic)) error=\(String(describing: error))")
    }
}
