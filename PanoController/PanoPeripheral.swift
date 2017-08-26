//
//  PanoPeripheral.swift
//  PanoController
//
//  Created by Laurentiu Badea on 8/12/17.
//  Copyright © 2017 Laurentiu Badea. All rights reserved.
//

import Foundation
import CoreBluetooth

class PanoPeripheral : NSObject, CBPeripheralDelegate {
    static let status = Status.status
    static let config = Config.config

    static let serviceUUID = CBUUID(string: "2017")
    static let configCharUUID = CBUUID(string: "0001")
    static let statusCharUUID = CBUUID(string: "0002")
    static let cmdCharUUID = CBUUID(string: "0003")

    var peripheral: CBPeripheral?

    init(_ peripheral: CBPeripheral) {
        super.init()
        self.peripheral = peripheral
        self.peripheral!.delegate = self
        peripheral.discoverServices(nil)
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
                peripheral.setNotifyValue(true, for: thisCharacteristic)
                peripheral.readValue(for: thisCharacteristic)
            }
            if thisCharacteristic.uuid == PanoPeripheral.configCharUUID {
                print("sending \(PanoPeripheral.config.pack())")
                peripheral.writeValue(PanoPeripheral.config.pack(), for: thisCharacteristic, type: .withoutResponse)
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
