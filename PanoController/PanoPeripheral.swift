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
    func panoPeripheral(_ panoPeripheral: PanoPeripheral, didReceiveLine: String)
}

class PanoPeripheral : NSObject, CBPeripheralDelegate {
    var dataIn = Data()
    var dataInReadOffset = 0
    var dataOut = Data()
    var dataOutWriteOffset = 0
    let blockSize = 20     // how many bytes we can send at once - should read from characteristic
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
    var uartTxChar: CBCharacteristic?
    var uartRxChar: CBCharacteristic?

    var peripheral: CBPeripheral?

    init(_ peripheral: CBPeripheral) {
        super.init()
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
        if !connected && uartRxChar != nil && uartTxChar != nil {
            connected = true
            delegate?.panoPeripheralDidConnect(self)
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
            if service.uuid == PanoPeripheral.uartServiceUUID {
                if thisCharacteristic.uuid == PanoPeripheral.uartTxCharUUID {
                    uartTxChar = thisCharacteristic
                }
                if thisCharacteristic.uuid == PanoPeripheral.uartRxCharUUID {
                    uartRxChar = thisCharacteristic
                    peripheral.setNotifyValue(true, for: uartRxChar!)
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
            dataIn.append(characteristic.value!)
            //let s = String(data: characteristic.value!, encoding: .ascii)
            //print("Received \(s)")
            while let line = readLine() {
                print(">>> \(line)")
                delegate?.panoPeripheral(self, didReceiveLine: line)
            }

        default:
            print("Received update for unknown characteristic \(String(describing: characteristic))")
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        //print("didUpdateNotificationStateFor \(String(describing: characteristic))")
    }

    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        //print("didWriteValueForCharacteristic \(String(describing: characteristic)) error=\(String(describing: error))")
        // send more data
        sendDataOut()
    }

    // MARK: - UART Read-Write

    // Send a block of data from dataOut, emptying it when finished
    private func sendDataOut(){
        let end = min(dataOutWriteOffset + blockSize, dataOut.count)
        if end > 0 {
            let buf = dataOut.subdata(in: dataOutWriteOffset..<end)
            dataOutWriteOffset = end
            self.peripheral?.writeValue(buf, for: uartTxChar!, type: .withResponse)
            if end == dataOut.count {
                dataOut.removeAll(keepingCapacity: true)
                dataOutWriteOffset = 0
            }
        }
    }

    func writeLine(_ line: String){
        if let data = line.data(using: .ascii, allowLossyConversion: true) {
            dataOut.append(data)
            dataOut.append(10)
        }
        if dataOutWriteOffset == 0 {
            sendDataOut()
        }
    }

    let eol = "\r\n".data(using: .ascii)!
    func readLine() -> String? {
        let line: String?
        if let end = (dataInReadOffset..<dataIn.count).index( where: { eol.contains(dataIn[$0]) } ) {
            line = String(data: dataIn.subdata(in: dataInReadOffset..<end), encoding: .ascii)
            dataInReadOffset = (end..<dataIn.count).index( where: { dataIn[$0] > 32 }) ?? end+1
            if dataInReadOffset >= dataIn.count {
                dataIn.removeAll(keepingCapacity: true)
                dataInReadOffset = 0
            }
        } else {
            line = nil
        }
        return line
    }

    // MARK: - CustomStringConvertible

    override var description: String {
        get {
            return "<PanoController connected=\(connected) ready=\(isReady) name=\(name)>"
        }
    }
}
