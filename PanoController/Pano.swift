//
//  Pano.swift
//  PanoController
//
//  Created by Laurentiu Badea on 10/15/17.
//  Copyright © 2017-2019 Laurentiu Badea. All rights reserved.
//

import Foundation

extension String {
    /**
     Parse a string of space-separated key=value pairs into a Dictionary.
     Unrecognized elements are ignored.
     - Returns: Dictionary like `["AAA": "1", "BBB": "2"]` for an input of `"FOO AAA=1 BBB=2"`
     */
    func kvToDict() -> [String: String]? {
        let vals = self
            .split(separator: " ")
            .compactMap { (s) -> (String, String)? in
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
    /// Convert Data containing space-separated key=value pairs into a Dictionary - see String.kvToDict
    func kvToDict() -> [String: String]? {
        if let kvPairs = String.init(data: self, encoding: .utf8){
            return kvPairs.kvToDict()
        }
        return nil
    }
}

extension Double {
    /**
     Format double with given number of decimal points
     - Parameter precision: number of decimal points
     - Returns: formatted string: "1.23"
     */
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

    enum GridOrder {
        case RowFirst
        case ColumnFirst
    }

    // Configuration
    /// Focal length, in mm
    var focalLength = 35.0
    /// Sensor width, in mm
    var sensorWidth = 36.0
    /// Sensor height, in mm
    var sensorHeight = 24.0
    /// Shutter speed, in seconds
    var shutter = 0.1
    /// Time to wait before shutter actuation, in seconds
    var preShutter = 0.0
    /// Time to wait after shutter actuation, in seconds
    var postShutter = 0.0
    /// Max time to wait for platform shake low enough to take the photo, in seconds
    var zeroMotionWait = 0.0
    /// If true, hold shutter down for the entire shutter period instead of a few ms
    var shutterLong = false
    /// Number of shots to take in each position
    var shotCount = 1
    /// Panorama horizontal field of view, in degrees 1-360°
    var panoHorizFOV = 180.0
    /// Panorama vertical field of view, in degrees 1-180°
    var panoVertFOV = 90.0
    /// How much should the photo edges overlap, 0.01 - 0.9 for 1% - 90%
    var overlap = 0.2
    /// Allow continuous horizontal rotation, set only if there are no external cables to wrap
    var infiniteRotation = false
    /// How many stops of Image Stabilization we can count on
    var stabilizationStops = 0.0
    /// Pano execution order, RowFirst does complete rows, ColumnFirst does complete columns
    var gridOrder: GridOrder = .RowFirst

    // State
    /// linear position of this shot (0..<rows*cols)
    var position = 0

    // Computed values
    /// Horizontal move to advance one cell, in degrees
    var horizCellMove = 0.0
    /// Vertical move to advance one cell, in degrees
    var vertCellMove = 0.0
    /// Computed number of rows needed to cover the horizontal pano FOV
    var rows = 0
    /// Computed number of columns needed to cover the vertical pano FOV
    var cols = 0

    // G-Code Interpreter Status and Configs
    /// Hardware platform configuration received from remote
    var platform: [String: String] = [:]

    /// Initialized G-Code Generator
    var program: AnyIterator<String>?

    // While harder on the eyes, this approach allows in-flight changing parameters like position, for example
    /**
     Generate the G-code program to execute the current pano step by step.
     - Returns: iterator over a list of dynamically generated strings containing the G-code program
     */
    var gCode: AnyIterator<String> {
        computeGrid()
        var commandBuffer = ["M17 M320 G1 G91 G92.1",
                             "M203 A\(platform["MaxSpeedA"]!) C\(platform["MaxSpeedC"]!)",
                             "M202 A\(Int(18*Double(platform["MaxAccelA"]!)!/focalLength)) C\(Int(18*Double(platform["MaxAccelC"]!)!/focalLength))",
                             "M503"].makeIterator()
        self.position = 0
        var running = true
        return AnyIterator<String> {
            // Awkward state keeping. There has got to be a better way! Maybe a queue ?
            // Send from buffer as long as it's not empty
            if let cmd = commandBuffer.next() {
                return cmd
            } else {
                // Command buffer is empty, replace with a new one
                var commands: [String] = []
                if running {
                    // Actual program
                    //commands.append(";\(self.position+1)/\(self.rows*self.cols)")
                    if (self.preShutter > 0){
                        commands.append("G4 S\(self.preShutter.format())")
                    }
                    if self.zeroMotionWait > 0 && self.shutter > 0 {
                        let steadyTarget = Pano.steadyTarget(for: self.sensorHeight, at: self.focalLength, resolution: 4000, shutter: self.shutter, stops: self.stabilizationStops)
                        commands.append("M116 S\(self.zeroMotionWait.format(1)) Q\(steadyTarget.format(3))")
                    }
                    if self.shutter > 0 {
                        for _ in 0..<self.shotCount {
                            commands.append("M240 S\(self.shutter.format()) Q\(self.shutterLong ? 1 : 0)")
                            if self.postShutter > 0 {
                                commands.append("G4 S\(self.postShutter.format())")
                            }
                        }
                    } else {
                        commands.append("M0")
                    }
                    let (horizMove, vertMove) = self.moveToNextPosition()
                    if horizMove != 0 || vertMove != 0 {
                        commands.append("A\(horizMove.format(2)) C\(vertMove.format(2)) M114 M503 P2")
                    } else {
                        // End of program
                        running = false
                        commands += ["G0 G28", "M18 M114 M503"]
                    }
                }
                commandBuffer = commands.makeIterator()
                let cmd = commandBuffer.next()
                return cmd
            }
        }
    }

    /**
     Move to next grid position respecting current grid order
     - Returns: `(horizMove, vertMove)` as relative movement in degrees to reach the next cell in the pano sequence. Will return (0, 0) when end of pano is reached.
     */
    func moveToNextPosition() -> (Double, Double) {
        let horiz: Double
        let vert: Double
        switch gridOrder {
        case .RowFirst:
            (horiz, vert) = moveTo(to: position + 1)
        case .ColumnFirst:
            if position == rows * cols - 1 {
                (horiz, vert) = (0.0, 0.0)
            } else if position < (rows-1) * cols {
                (horiz, vert) = moveTo(to: position + cols)
            } else {
                 // last row, rewind to top (will return 0,0 when out of bounds)
                (horiz, vert) = moveTo(to: (position % cols) + 1 )
            }
        }
        return (horiz, vert)
    }

    /**
     Move to photo index position (0..<number of photos)
     - Parameter to: linear cell index aka photo number
     - Returns: `(horizMove, vertMove)` as relative movement in degrees to reach the next cell in the pano sequence, or `(0.0, 0.0)` if the next cell is outside the pano bounds.
     */
    func moveTo(to targetPosition: Int) -> (Double, Double) {
        return moveTo(row: targetPosition / cols, col: targetPosition % cols);
    }

    /**
     Move to specified grid coordinates
     - Parameter row: requested row position 0..<rows
     - Parameter col: request column position 0..<col
     - Returns: `(horizMove, vertMove)` as relative movement in degrees to reach the requested grid location, or `(0.0, 0.0)` if the location is outside the pano bounds.
     */
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

    /// Calculate shot-to-shot horizontal/vertical head movement, taking overlap into account
    /// Must be called every time focal distance or panorama dimensions change.
    func computeGrid() {
        horizCellMove = Pano.lensFOV(for: sensorWidth, at: focalLength)
        vertCellMove = Pano.lensFOV(for: sensorHeight, at: focalLength)
        cols = gridFit(totalSize: panoHorizFOV, overlap: overlap, blockSize: &horizCellMove)
        rows = gridFit(totalSize: panoVertFOV, overlap: overlap, blockSize: &vertCellMove)
    }

    /**
     Helper method to calculate grid fit taking overlap into account
     - Parameter totalSize: entire grid size (1-360°)
     - Parameter overlap: min required overlap (0.01 - 0.99)
     - Parameter blockSize: initial (max) block size **(will be updated)**
     - Returns: new image count, and updates blockSize
     */
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

    /**
     Calculate lens field of view from focal length and sensor size
     - Parameter sensorSize: sensor size [mm] on the FOV axis requested
     - Parameter focalLength: focal length [mm]
     - Returns: field of view in degrees
     */
    static func lensFOV(for sensorSize: Double, at focalLength: Double) -> Double {
        // https://en.wikipedia.org/wiki/Angle_of_view
        return 360.0 * atan(sensorSize / 2.0 / focalLength) / Double.pi
    }

    /**
     Calculate max permissible angular velocity [°/s] for a given exposure
     - Parameter sensorSize: sensor size [mm] on the FOV axis requested
     - Parameter focalLength: focal length [mm]
     - Parameter resolution: sensor resolution [pixels] where sensorSize was measured
     - Parameter shutter: shutter speed [seconds]
     - Parameter stops: image stabilization stops to be taken into account
     - Returns: max allowed angular velocity in [°/s]
     */
    static func steadyTarget(for sensorSize: Double, at focalLength: Double, resolution: Int, shutter: Double, stops: Double = 0) -> Double {
        return lensFOV(for: sensorSize, at: focalLength) / Double(resolution) / shutter * pow(2.0, stops)
    }

    /// Start sending/executing the generated gCode
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
        case .gridOrder:   self.gridOrder = value as! GridOrder
        case .infiniteRotation: self.infiniteRotation = value as! Bool
        case .zeroMotionWait: self.zeroMotionWait = value as! Double
        case .stabilized: self.stabilizationStops = value as! Bool ? 2 : 0;
        }
        computeGrid()
    }
}
