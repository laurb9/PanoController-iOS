//
//  Pano.swift
//  PanoController
//
//  Created by Laurentiu Badea on 10/15/17.
//  Copyright © 2017 Laurentiu Badea. All rights reserved.
//

import Foundation

extension String {
    func kvToDict() -> [String: String]? {
        let vals = self
            .split(separator: "\t")
            .flatMap { (s) -> (String, String)? in
                let kv = s.split(separator: "=", maxSplits: 1)
                if kv.count == 2 {
                    let key = kv[0], val = kv[1]
                    return (String(key), String(val))
                } else {
                    return nil
                }
        }
        if vals.count > 0 {
            return Dictionary(vals, uniquingKeysWith: { (old, new) in new })
        } else {
            return nil
        }
    }
}

extension Data {
    // Convert Data containing key=value pairs into a Dictionary<String:String>
    func kvToDict() -> [String: String]? {
        if let kvPairs = String.init(data: self, encoding: .utf8){
            return kvPairs.kvToDict()
        }
        return nil
    }
}

extension Double {
    func format(_ precision: Int) -> String {
        return String(format: "%.\(precision)f", self)
    }
    func format() -> String {
        // this avoid trailing 0s but might go to e-notation beyond 8 digits
        // should use this for known values
        return String(format: "%.8g", self)
    }
}

class Pano : NSObject {
    enum State {
        case Idle
        case Running
        case Paused
        case End
    }
    var state: State = .Idle

    // Configuration
    var focalLength = 35.0     // mm
    var sensorWidth = 36.0     // mm
    var sensorHeight = 24.0    // mm
    var shutter = 0.1          // s
    var preShutter = 0.0       // s
    var postShutter = 0.0      // s
    var zeroMotionWait = 0.0   // s
    var shutterLong = false
    var shotCount = 1
    var panoHorizFOV = 180.0   // 1-360°
    var panoVertFOV = 90.0    // 1-180°
    var overlap = 0.2          // 0 - 1 (representing 0% - 100%)
    var infiniteRotation = false  // allow continuous horizontal rotation - no cables to tangle
    var stabilizationStops = 0.0  // how many stops of IS we should count on

    // State
    var position = 0

    // Computed values
    var horizCellMove = 0.0    // °
    var vertCellMove = 0.0     // °
    var rows = 0
    var cols = 0

    // G-Code Interpreter Status and Configs
    var platform: [String: String] = [:]
    var program: AnyIterator<String>?

    // Generate the gCode program to execute the current pano step by step
    // While harder on the eyes, this allows in-flight changing parameters like position, for example
    var gCode: AnyIterator<String> {
        computeGrid()
        var commandBuffer = ["M17 M320 G1 G91 G92 A0 C0",
                             "M203 A\(platform["MaxSpeedA"]!) C\(platform["MaxSpeedC"]!)",
                             "M202 A\(18*Double(platform["MaxAccelA"]!)!/focalLength) C\(18*Double(platform["MaxAccelC"]!)!/focalLength)",
                             "M503"].makeIterator()
        self.position = 0
        var targetPosition = 0  // moveTo() keeps track of the previous position to calculate offsets, so we cannot modify it directly
        return AnyIterator<String> {
            // Awkward state keeping. There has got to be a better way! Maybe a queue ?
            // Send from buffer as long as it's not empty
            if let cmd = commandBuffer.next() {
                return cmd
            } else {
                // Command buffer is empty, replace with a new one
                var commands: [String] = []
                if targetPosition < self.rows * self.cols {
                    // Actual program
                    commands.append(";\(targetPosition+1)/\(self.rows*self.cols)")
                    let (horizMove, vertMove) = self.moveTo(to: targetPosition)
                    commands.append("A\(horizMove.format(2)) C\(vertMove.format(2)) M114 M503 P2")
                    if (self.preShutter > 0){
                        commands.append("G4 S\(self.preShutter.format())")
                    }
                    if self.zeroMotionWait > 0 && self.shutter > 0 {
                        let steadyTarget = Pano.steadyTarget(for: self.sensorHeight, at: self.focalLength, resolution: 4000, shutter: self.shutter, stops: self.stabilizationStops)
                        commands.append("M116 S\(self.zeroMotionWait.format(1)) Q\(steadyTarget.format(3))")
                    }
                    if self.shutter > 0 {
                        for _ in 0..<self.shotCount {
                            commands.append("M240 S\(self.shutter.format()) Q\(self.shutterLong ? 1 : 0) R\(self.postShutter.format())")
                        }
                    } else {
                        commands.append("M0")
                    }
                    targetPosition += 1
                    if targetPosition == self.rows * self.cols {
                        // End of program
                        commands += ["G0 G28", "M18 M114 M503"]
                    }
                }
                commandBuffer = commands.makeIterator()
                let cmd = commandBuffer.next()
                return cmd
            }
        }
    }

    // Move to grid position by photo index (0-number of photos)
    func moveTo(to targetPosition: Int) -> (Double, Double) {
        return moveTo(row: targetPosition / cols, col: targetPosition % cols);
    }

    // Move to specified grid position
    // @param row: requested row position [0 - vert_count)
    // @param col: requested col position [0 - horiz_count)
    func moveTo(row: Int, col: Int) -> (Double, Double) {
        let currentRow = position / cols
        let currentCol = position % cols
        var horizMove = 0.0
        var vertMove = 0.0

        if (currentRow >= rows ||
            row >= rows ||
            col >= cols ||
            col < 0 ||
            row < 0){
            // beyond last/first row or column, cannot move there.
            return (horizMove, vertMove);
        }

        if (currentCol != col){
            // horizontal adjustment needed
            horizMove = Double(col - currentCol) * horizCellMove;
            if (infiniteRotation){
                // Use shortest path around the circle
                // Good idea if on batteries, bad idea when power cable in use
                if (abs(horizMove) > 180){
                    if (horizMove < 0){
                        horizMove = 360 + horizMove;
                    } else {
                        horizMove = horizMove - 360;
                    }
                }
            }
        }
        if (currentRow != row){
            // vertical adjustment needed
            vertMove = Double(currentRow - row) * vertCellMove;
        }
        position = row * cols + col;
        return (horizMove, vertMove)
    }

    // Calculate shot-to-shot horizontal/vertical head movement, taking overlap into account
    // Must be called every time focal distance or panorama dimensions change.
    func computeGrid() {
        horizCellMove = Pano.lensFOV(for: sensorWidth, at: focalLength)
        vertCellMove = Pano.lensFOV(for: sensorHeight, at: focalLength)
        cols = gridFit(totalSize: panoHorizFOV, overlap: overlap, blockSize: &horizCellMove)
        rows = gridFit(totalSize: panoVertFOV, overlap: overlap, blockSize: &vertCellMove)
    }

    // Helper to calculate grid fit with overlap
    // @param totalSize: entire grid size (1-360 degrees)
    // @param overlap: min required overlap (0.01 - 0.99)
    // @param blockSize: ref to initial (max) block size (will be updated)
    // @return count: ref to image count (will be updated)
    func gridFit(totalSize: Double, overlap: Double, blockSize: inout Double) -> Int {
        var totalSize = totalSize;
        var count = 1;
        if (blockSize <= totalSize){
            // For 360 pano, we need to cover entire circle plus overlap.
            // For smaller panos, we cover the requested size only.
            if (totalSize != 360){
                totalSize = totalSize - blockSize * overlap;
            }
            blockSize = blockSize * (1-overlap);
            count = Int(ceil(totalSize / blockSize));
            blockSize = totalSize / Double(count);
        }
        return count
    }

    // Calculate lens field of view from focal length and sensor size
    static func lensFOV(for sensorSize: Double, at focalLength: Double) -> Double {
        // https://en.wikipedia.org/wiki/Angle_of_view
        return 360.0 * atan(sensorSize / 2.0 / focalLength) / Double.pi
    }

    // Calculate max angular velocity [°/s] for this shutter, focal length and sensor size
    static func steadyTarget(for sensorSize: Double, at focalLength: Double, resolution: Int, shutter: Double, stops: Double = 0) -> Double {
        return lensFOV(for: sensorSize, at: focalLength) / Double(resolution) / shutter * pow(2.0, stops)
    }

    // Start sending/executing the generated gCode
    func startProgram(_ panoPeripheral: PanoPeripheral) {
        state = .Running
        program = gCode
        panoPeripheral.writeLine("%") // the rest of execution is in panoPeripheralDidReceiveLine
    }
}

// MARK: -- PanoPeripheralDelegate

extension Pano : PanoPeripheralDelegate {
    func panoPeripheralDidConnect(_ panoPeripheral: PanoPeripheral){
        // Request firmware and configuration info on connect
        panoPeripheral.writeLine("M115 M117 M114 M503 P7")
    }

    func panoPeripheralDidDisconnect(_ panoPeripheral: PanoPeripheral){
    }

    func panoPeripheral(_ panoPeripheral: PanoPeripheral, didReceiveLine line: String){
        if let updates = line.kvToDict() {
            // Received status updates as a k=v structure
            platform.merge(updates, uniquingKeysWith: { (_, new) in new })
        } else if state == .Running && line.starts(with: "ok") {
            // Received ack for previous command, send next one
            if let command = program?.next() {
                print(command)
                panoPeripheral.writeLine(command)
            } else {
                // End of program
                state = .End
            }
        }
    }
}

// MARK: -- MenuDelegate
// Receive user menu selections and update the configuration

extension Pano: MenuItemDelegate {

    func menuItem(didSet index: MenuItemKey, value: Any){
        switch index {
        case .horizFOV:    self.panoHorizFOV = Double(value as! Int)
        case .vertFOV:     self.panoVertFOV = Double(value as! Int)
        case .focalLength: self.focalLength = Double(value as! Int)
        case .shutter:     self.shutter = value as! Double
        case .preShutter:  self.preShutter = value as! Double
        case .postShutter: self.postShutter = value as! Double
        case .shutterLong: self.shutterLong = value as! Bool
        case .shotCount:   self.shotCount = value as! Int
        case .aspect:
            switch value as! Int {
            case 32: (self.sensorWidth, self.sensorHeight) = (36, 24)
            case 23: (self.sensorWidth, self.sensorHeight) = (24, 36)
            default: break
            }
        case .infiniteRotation: self.infiniteRotation = value as! Bool
        case .zeroMotionWait: self.zeroMotionWait = value as! Double
        case .stabilized: self.stabilizationStops = value as! Bool ? 2 : 0;
        }
        computeGrid()
    }
}
