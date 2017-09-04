//
//  PanoPeripheral.swift
//  PanoController
//
//  Created by Laurentiu Badea on 8/12/17.
//  Copyright © 2017 Laurentiu Badea. All rights reserved.
//

import Foundation
import CoreBluetooth

protocol PanoPeripheralDelegate {
    func panoPeripheralDidConnect(_ panoPeripheral: PanoPeripheral)
    func panoPeripheralDidDisconnect(_ panoPeripheral: PanoPeripheral)
    func panoPeripheral(_ panoPeripheral: PanoPeripheral, didReceiveStatus status: Status)
}

class PanoPeripheral : NSObject, CBPeripheralDelegate, ConfigDelegate {
    let status: Status
    let config: Config
    var delegate: PanoPeripheralDelegate?
    var connected: Bool = false
    var isReady: Bool {
        checkIfReady()
        return connected && peripheral?.state == .connected
    }

    static let uartServiceUUID = CBUUID(string: "6E400001-B5A3-F393-E0A9-E50E24DCCA9E")
    static let uartTxCharUUID = CBUUID(string: "6E400002-B5A3-F393-E0A9-E50E24DCCA9E")
    static let uartRxCharUUID = CBUUID(string: "6E400003-B5A3-F393-E0A9-E50E24DCCA9E")
    static let serviceUUID = CBUUID(string: "2017")
    static let statusCharUUID = CBUUID(string: "0002")
    static let cmdCharUUID = CBUUID(string: "0003")
    var statusChar: CBCharacteristic?
    var uartTxChar: CBCharacteristic?
    var uartRxChar: CBCharacteristic?
    var cmdChar: CBCharacteristic?

    var peripheral: CBPeripheral?

    init(_ peripheral: CBPeripheral) {
        self.status = Status()
        self.config = Config()
        super.init()
        config.delegate = self
        self.peripheral = peripheral
        self.peripheral!.delegate = self
        peripheral.discoverServices(nil)
    }

    convenience init(_ peripheral: CBPeripheral, delegate: PanoPeripheralDelegate) {
        self.init(peripheral)
        self.delegate = delegate
    }

    var name: String {
        return peripheral?.name ?? ""
    }

    func checkIfReady() {
        if !connected &&
            statusChar != nil &&
            uartTxChar != nil &&
            uartRxChar != nil &&
            cmdChar != nil {
            connected = true
            sendConfig()
            delegate?.panoPeripheralDidConnect(self)
        }
    }

    // Mark: - ConfigDelegate

    func config(_ config: Config, didSetIndex index: String, withValue value: Int16) {
        if let characteristic = uartTxChar {
            var data = Data()
            config.serialize(index: index, into: &data)
            print("sending \(data) for \(index) to \(characteristic)")
            peripheral?.writeValue(data, for: characteristic, type: .withResponse)
        }
    }

    // Mark: - Pano Device Control Send/Receive operations

    func readStatus() -> Status {
        return status
    }

    func sendConfig() {
        for key in config.keys {
            config(config, didSetIndex: key, withValue: config[key])
        }
    }

    enum Command : UInt8 {
        case start = 0x61
        case cancel = 0x62
        case pause = 0x63
        case shutter = 0x64
        case setHome = 0x65
        case goHome = 0x66
        case sendStatus = 0x67
        case freeMove = 0x68
        case incMove = 0x69
    }
    enum Direction : UInt8 {
        case forward = 0x3e
        case back = 0x3c
        case up = 0x5e
        case down = 0x76
    }
    func sendFreeMove(horizontal: Float, vertical: Float) {
        if let characteristic = cmdChar ?? uartTxChar {
            let horiz = Int16(horizontal*100)
            let vert = Int16(vertical*100)
            var data = Data(bytes: [Command.freeMove.rawValue])
            Config.serialize(horiz, into: &data)
            Config.serialize(vert, into: &data)
            print("sending FreeMove(\(horiz), \(vert) (\(data)) to \(characteristic)")
            peripheral?.writeValue(data, for: characteristic, type: .withResponse)
        }
    }
    func sendIncMove(_ direction: Direction){
        if let characteristic = cmdChar ?? uartTxChar {
            var data = Data(bytes: [Command.incMove.rawValue])
            data.append(direction.rawValue)
            print("sending IncMove(\(direction)) (\(data)) to \(characteristic)")
            peripheral?.writeValue(data, for: characteristic, type: .withResponse)
        }
    }
    func send(command: Command) {
        // WIP, placeholder code
        if let characteristic = cmdChar ?? uartTxChar {
            let data = Data(bytes: [command.rawValue])
            print("sending command \(command) (\(data)) to \(characteristic)")
            peripheral?.writeValue(data, for: characteristic, type: .withResponse)
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
            if service.uuid == PanoPeripheral.serviceUUID {
                if thisCharacteristic.uuid == PanoPeripheral.statusCharUUID {
                    statusChar = thisCharacteristic
                    peripheral.setNotifyValue(true, for: statusChar!)
                    peripheral.readValue(for: statusChar!)
                }
                if thisCharacteristic.uuid == PanoPeripheral.cmdCharUUID {
                    cmdChar = thisCharacteristic
                }
            }
            if service.uuid == PanoPeripheral.uartServiceUUID {
                if thisCharacteristic.uuid == PanoPeripheral.uartTxCharUUID {
                    uartTxChar = thisCharacteristic
                }
                if thisCharacteristic.uuid == PanoPeripheral.uartRxCharUUID {
                    uartRxChar = thisCharacteristic
                }
            }
            //peripheral.discoverDescriptors(for: thisCharacteristic)
        }
        checkIfReady()
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
            print(characteristic.value!) // not expecting to receive anything, but maybe leave code for future

        case PanoPeripheral.statusCharUUID:
            status.deserialize(characteristic.value!)
            delegate?.panoPeripheral(self, didReceiveStatus: status)

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

    // MARK: -- CustomStringConvertible

    override var description: String {
        get {
            return "<PanoController connected=\(connected) ready=\(isReady) name=\(name)>"
        }
    }
}
