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
}

class Config: CustomStringConvertible {
    var focal: Int16 = 35
    var shutter: Int16 = 100
    var pre_shutter: Int16 = 100
    var post_wait: Int16 = 500
    var long_pulse: Int16 = 0
    var aspect: Int16 = 1
    var shots: Int16 = 1
    var motors_enable: Int16 = 0
    var motors_on: Int16 = 0
    var display_invert: Int16 = 0
    var horiz: Int16 = 360
    var vert: Int16 = 160

    func pack() -> Data {
        var data = Data()
        data.append(UnsafeBufferPointer(start: &focal, count: 1))
        data.append(UnsafeBufferPointer(start: &shutter, count: 1))
        data.append(UnsafeBufferPointer(start: &pre_shutter, count: 1))
        data.append(UnsafeBufferPointer(start: &post_wait, count: 1))
        data.append(UnsafeBufferPointer(start: &long_pulse, count: 1))
        data.append(UnsafeBufferPointer(start: &aspect, count: 1))
        data.append(UnsafeBufferPointer(start: &shots, count: 1))
        data.append(UnsafeBufferPointer(start: &motors_enable, count: 1))
        data.append(UnsafeBufferPointer(start: &motors_on, count: 1))
        data.append(UnsafeBufferPointer(start: &display_invert, count: 1))
        data.append(UnsafeBufferPointer(start: &horiz, count: 1))
        data.append(UnsafeBufferPointer(start: &vert, count: 1))
        return data
    }

    // MARK: -- CustomStringConvertible

    var description: String {
        get {
            return "<Config focal=\(focal) shutter=\(shutter)>"
        }
    }
}

class Status: CustomStringConvertible {
    var battery: Int16 = 0
    var motors_on: Int16 = 0
    var display_invert: Int16 = 0
    var running: Int16 = 0
    var paused: Int16 = 0
    var position: Int16 = 0
    var steady_delay_avg: Int16 = 0
    var horiz_offset: Float32 = 0.0
    var vert_offset: Float32 = 0.0

    func update(with data: Data) {
        var offset = 0
        (battery, offset) = data.readVal(start: offset)
        (motors_on, offset) = data.readVal(start: offset)
        (display_invert, offset) = data.readVal(start: offset)
        (running, offset) = data.readVal(start: offset)
        (paused, offset) = data.readVal(start: offset)
        (position, offset) = data.readVal(start: offset)
        (steady_delay_avg, offset) = data.readVal(start: offset)
        (horiz_offset, offset) = data.readVal(start: offset)
        (vert_offset, offset) = data.readVal(start: offset)
        if offset != data.count {
            print("Warning: Data size mismatch: read \(offset), received \(data.count)")
        }
    }

    // MARK: -- CustomStringConvertible

    var description: String {
        get {
            return "<Status running=\(running) position=\(position) battery=\(battery)>"
        }
    }
}
