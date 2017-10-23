//
//  Pano.swift
//  PanoController
//
//  Created by Laurentiu Badea on 10/15/17.
//  Copyright © 2017 Laurentiu Badea. All rights reserved.
//

import Foundation

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

    // Configuration
    var focalLength = 35.0     // mm
    var sensorWidth = 36.0     // mm
    var sensorHeight = 24.0    // mm
    var shutter = 0.1          // s
    var preShutter = 0.0       // s
    var postShutter = 0.0      // s
    var shutterLong = false
    var shotCount = 1
    var panoHorizFOV = 360.0   // 1-360°
    var panoVertFOV = 180.0    // 1-180°
    var overlap = 0.2          // 0 - 1 (representing 0% - 100%)

    // State
    var position = 0

    // Computed values
    var horizCellMove = 0.0    // °
    var vertCellMove = 0.0     // °
    var rows = 0
    var cols = 0

    // Generate the gCode commands to execute the current pano
    func gCode() -> [String] {
        var gcode: Array<String> = []
        computeGrid()
        let steadyTarget = Pano.steadyTarget(for: sensorHeight, at: focalLength, resolution: 4000, shutter: shutter)
        position = 0
        gcode.append("M17 G1 G91 G92 A0 C0")
        for row in 0..<rows {
            for col in 0..<cols {
                let (horizMove, vertMove) = moveTo(row: row, col: col)
                gcode.append("A\(horizMove.format(2)) C\(vertMove.format(2))")
                if (preShutter > 0){
                    gcode.append("G4 P\(preShutter.format()))")
                }
                gcode.append("M116 P10 Q\(steadyTarget.format(0))")
                if (shutter > 0){
                    for _ in 0..<shotCount {
                        gcode.append("M240 P\(shutter.format()) Q\(shutterLong ? 1 : 0) R\(postShutter.format())")
                    }
                } else {
                    gcode.append("M0")
                }
            }
        }
        gcode.append("G0 G28")
        gcode.append("M18")
        return gcode
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
            // figure out shortest path around the circle
            // FIXME: good idea if on batteries, bad idea when power cable in use
            horizMove = Double(col - currentCol) * horizCellMove;
            if (abs(horizMove) > 180){
                if (horizMove < 0){
                    horizMove = 360 + horizMove;
                } else {
                    horizMove = horizMove - 360;
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

    // Calculate max angular velocity [µ°/s] for this shutter, focal length and sensor size
    static func steadyTarget(for sensorSize: Double, at focalLength: Double, resolution: Int, shutter: Double) -> Double {
        return 1000000 * shutter * lensFOV(for: sensorSize, at: focalLength) / Double(resolution)
    }
}
