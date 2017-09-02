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
        "focal": 41,
        "shutter": 42,
        "pre_shutter": 43,
        "post_wait": 44,
        "long_pulse": 45,
        "aspect": 46,
        "shots": 47,
        "motors_enable": 48,
        "motors_on": 49,
        "display_invert": 50,
        "horiz": 51,
        "vert": 52
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

    func serialize(index: String, into data: inout Data){
        var c = Config.keyCodeMap[index]!
        data.pack(&c)
        var v = self[index]
        data.pack(&v)
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
