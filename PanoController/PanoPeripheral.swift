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
    var status: Status
    var config: Config

    struct PanoControllerService {
        static let UUID = CBUUID(string: "2017")
        struct ConfigCharacteristic {
            static let UUID = CBUUID(string: "0001")
        }
        struct StatusCharacteristic {
            static let UUID = CBUUID(string: "0002")
        }
    }
    var peripheral: CBPeripheral?

    init(_ peripheral: CBPeripheral) {
        status = Status()
        config = Config() // should load from settings
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
            if thisCharacteristic.uuid == PanoControllerService.StatusCharacteristic.UUID {
                peripheral.setNotifyValue(true, for: thisCharacteristic)
                peripheral.readValue(for: thisCharacteristic)
            }
            if thisCharacteristic.uuid == PanoControllerService.ConfigCharacteristic.UUID {
                //print("sending \(config.pack())")
                //peripheral.writeValue(config.pack(), for: thisCharacteristic, type: .withoutResponse)
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
        case PanoControllerService.ConfigCharacteristic.UUID:
            print(characteristic.value!)

        case PanoControllerService.StatusCharacteristic.UUID:
            print(characteristic.value!)
            status.update(with: characteristic.value!)
            print(status)

        default:
            print("Received update for unknown characteristic \(String(describing: characteristic))")
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        print("didUpdateNotificationStateFor \(String(describing: characteristic))")
    }
}
