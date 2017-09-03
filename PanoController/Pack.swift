//
//  Pack.swift
//  PanoController
//
//  Created by Laurentiu Badea on 8/20/17.
//  Copyright © 2017 Laurentiu Badea. All rights reserved.
//

import Foundation

// Add binary unpacking to Data

extension Data {
    func readVal<T>(start: Int, length: Int) -> T {
        return self.subdata(in: start..<start+length).withUnsafeBytes { $0.pointee }
    }
    func readVal<T>(start: Int) -> (T, Int) {
        let length = MemoryLayout<T>.size
        return (self.readVal(start: start, length: length), start+length)
    }
    mutating func pack<T: Integer >(_ val: inout T){
        self.append(UnsafeBufferPointer(start: &val, count: 1))
    }
}

// Add binary pack/unpack to Integer types

extension Integer {
    func pack(into data: inout Data){
        var tmp = self
        data.append(UnsafeBufferPointer(start: &tmp, count: 1))
    }
    func packed() -> Data {
        var data = Data()
        self.pack(into: &data)
        return data
    }
}

// Persistent Configuration dictionary

protocol DictionaryObserver {
    func didSet(_ config: Config, index: String, value: Int16)
}

class Config: NSObject {
    var observer: DictionaryObserver?

    // The list below contains all the keys allowed and a numeric identifier
    static private let keyCodeMap: Dictionary<String, UInt8> = [
        "focal": 0x41,
        "shutter": 0x42,
        "pre_shutter": 0x43,
        "post_wait": 0x44,
        "long_pulse": 0x45,
        "aspect": 0x46,
        "shots": 0x47,
        "motors_enable": 0x48,
        "motors_on": 0x49,
        "display_invert": 0x4A,
        "horiz": 0x4B,
        "vert": 0x4C
    ]

    // shadow dict with the actual KV pairs
    var _config: Dictionary<String, Int16> = [:]

    subscript(index: String) -> Int16 {
        get {
            return _config[index]!
        }
        set(newValue) {
            if Config.keyCodeMap[index] != nil {
                _config[index] = newValue
                print("Config[\(index)]=\(newValue)")
                observer?.didSet(self, index: index, value: newValue)
            }
        }
    }

    var keys: [String] {
        var k: [String] = []
        for key in _config.keys {
            k.append(key)
        }
        return k
    }

    // keyCode + hex string representation
    func serialize(index: String, into data: inout Data){
        var c = Config.keyCodeMap[index]!
        data.pack(&c)
        for c in self[index].packed().reversed() {
            var (low, high) = (0x30 + c & 0xf, 0x30 + (c & 0xf0) >> 4)
            data.pack(&high)
            data.pack(&low)
        }
    }

    // MARK: -- CustomStringConvertible

    override var description: String {
        get {
            return "<Config focal=\(_config["focal"]!) shutter=\(_config["shutter"]!)>"
        }
    }
}

class Status: NSObject {

    var horiz_offset: Float32 = 0.0
    var vert_offset: Float32 = 0.0
    var battery: Int16 = 0
    var position: Int16 = 0
    var steady_delay_avg: Int16 = 0
    var motors_on: Int8 = 0
    var running: Int8 = 0
    var paused: Int8 = 0

    func deserialize(_ data: Data) {
        var offset = 0
        (horiz_offset, offset) = data.readVal(start: offset)
        (vert_offset, offset) = data.readVal(start: offset)
        (battery, offset) = data.readVal(start: offset)
        (position, offset) = data.readVal(start: offset)
        (steady_delay_avg, offset) = data.readVal(start: offset)
        (motors_on, offset) = data.readVal(start: offset)
        (running, offset) = data.readVal(start: offset)
        (paused, offset) = data.readVal(start: offset)
        if offset != data.count {
            print("Warning: Data size mismatch: read \(offset), received \(data.count)")
        }
    }

    // MARK: -- CustomStringConvertible

    override var description: String {
        get {
            return "<Status running=\(running) position=\(position) battery=\(battery)>"
        }
    }
}
