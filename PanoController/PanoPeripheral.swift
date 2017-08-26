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

class PanoPeripheral : NSObject, CBPeripheralDelegate {
    static let status = Status.status
    static let config = Config.config

    static let serviceUUID = CBUUID(string: "2017")
    static let configCharUUID = CBUUID(string: "0001")
    static let statusCharUUID = CBUUID(string: "0002")
    static let cmdCharUUID = CBUUID(string: "0003")
    var statusChar: CBCharacteristic?
    var configChar: CBCharacteristic?
    var cmdChar: CBCharacteristic?

    var peripheral: CBPeripheral?

    init(_ peripheral: CBPeripheral) {
        super.init()
        self.peripheral = peripheral
        self.peripheral!.delegate = self
        peripheral.discoverServices(nil)
    }

    func sendConfig(_ config: Config) {
        if let characteristic = configChar {
            print("sending \(config.pack()) to \(characteristic)")
            peripheral?.writeValue(config.pack(), for: characteristic, type: .withoutResponse)
        }
    }

    func readStatus() -> Status {
        return PanoPeripheral.status
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
                //sendConfig(PanoPeripheral.config)
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
            PanoPeripheral.status.unpack(characteristic.value!)
            print(PanoPeripheral.status)

        default:
            print("Received update for unknown characteristic \(String(describing: characteristic))")
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        print("didUpdateNotificationStateFor \(String(describing: characteristic))")
    }
}
