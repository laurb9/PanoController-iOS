//
//  PanoControllerTests.swift
//  PanoControllerTests
//
//  Created by Laurentiu Badea on 7/30/17.
//  Copyright © 2017-2019 Laurentiu Badea. All rights reserved.
//

import XCTest
@testable import PanoController

class PanoControllerTests: XCTestCase {
    var pano: Pano!

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        pano = Pano()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testDataKVToDict(){
        let data = "FOO AAA=1111 BBB=1 CCC=ABC".data(using: .ascii)!
        XCTAssertEqual(data.kvToDict()!, ["AAA": "1111", "BBB": "1", "CCC": "ABC"])
    }

    func testCameraLensFOV(){
        XCTAssertEqual(Pano.lensFOV(for: 36, at: 8), 132.08, accuracy: 0.01)
        XCTAssertEqual(Pano.lensFOV(for: 36, at: 24), 73.74, accuracy: 0.01)
        XCTAssertEqual(Pano.lensFOV(for: 24, at: 600), 2.29, accuracy: 0.01)
        XCTAssertEqual(Pano.lensFOV(for: 3.6, at: 8.0), 25.36, accuracy: 0.01)
        XCTAssertEqual(Pano.lensFOV(for: 3.0, at: 2.4), 64.01, accuracy: 0.01)
    }

    func testGridFit(){
        var blockSize = 50.0
        // 50° with overlap of min 50% results in 5 movements of 25°
        let count = pano.gridFit(totalSize: 150, overlap: 0.5, blockSize: &blockSize)
        XCTAssertEqual(count, 5, "Image count")
        XCTAssertEqual(blockSize, 25.0, accuracy: 0.1, "Adjusted block size")
    }

    func testGridFit360(){
        var blockSize = 50.0
        // 50° with overlap of min 50% results in 15 movements of 24°
        let count = pano.gridFit(totalSize: 360, overlap: 0.5, blockSize: &blockSize)
        XCTAssertEqual(count, 15, "Image count")
        XCTAssertEqual(blockSize, 24.0, accuracy: 0.1, "Adjusted block size")
    }

    func testComputeGrid(){

        // 360 pano
        pano.focalLength = 35
        pano.panoVertFOV = 180
        pano.panoHorizFOV = 360
        pano.computeGrid()
        XCTAssertEqual(pano.cols, 9)
        XCTAssertEqual(pano.rows, 6)
        XCTAssertEqual(pano.horizCellMove, 40.00, accuracy: 0.01)
        XCTAssertEqual(pano.vertCellMove, 28.74, accuracy: 0.01)

        // regular field-limited pano
        pano.panoHorizFOV = 180
        pano.computeGrid()
        XCTAssertEqual(pano.cols, 4)
        XCTAssertEqual(pano.rows, 6)
        XCTAssertEqual(pano.horizCellMove, 42.28, accuracy: 0.01)
        XCTAssertEqual(pano.vertCellMove, 28.74, accuracy: 0.01)
    }

    func testPanoGCode() {
        pano.panoHorizFOV = 10
        pano.panoVertFOV = 10
        pano.focalLength = 300
        pano.overlap = 0.2
        pano.shutter = 1/100
        pano.preShutter = 0
        pano.postShutter = 0
        pano.zeroMotionWait = 0.1
        pano.platform = ["MaxSpeedA": "600",
                         "MaxSpeedC": "100",
                         "MaxAccelA": "360",
                         "MaxAccelC": "120"]
        let gcode = Array(pano.gCode)
        let expected = [
            "M17 M320 G1 G91 G92.1", "M203 A600 C100", "M202 A21 C7",
            "M503",
                                          "M116 S0.1 Q0.115", "M240 S0.01 Q0",
            "A4.31 C0.00 M114 M503 P2",   "M116 S0.1 Q0.115", "M240 S0.01 Q0",
            "A-4.31 C-3.03 M114 M503 P2", "M116 S0.1 Q0.115", "M240 S0.01 Q0",
            "A4.31 C0.00 M114 M503 P2",   "M116 S0.1 Q0.115", "M240 S0.01 Q0",
            "A-4.31 C-3.03 M114 M503 P2", "M116 S0.1 Q0.115", "M240 S0.01 Q0",
            "A4.31 C0.00 M114 M503 P2",   "M116 S0.1 Q0.115", "M240 S0.01 Q0",
            "G0 G28",
            "M18 M114 M503"]
        for (gcodeLine, expectedLine) in zip(gcode, expected) {
            XCTAssertEqual(gcodeLine, expectedLine)
        }
    }

    // Test complete G-Code generator for a 360 pano
    func testGCode360() {
        pano.panoHorizFOV = 360
        pano.panoVertFOV = 120
        pano.focalLength = 12.00
        pano.overlap = 0.2
        pano.shutter = 1/100
        pano.preShutter = 0
        pano.postShutter = 0.5
        pano.zeroMotionWait = 0
        pano.infiniteRotation = true
        pano.platform = ["MaxSpeedA": "600",
                         "MaxSpeedC": "100",
                         "MaxAccelA": "360",
                         "MaxAccelC": "120"]
        let gcode = Array(pano.gCode)
        let expected = [
            "M17 M320 G1 G91 G92.1", "M203 A600 C100", "M202 A540 C180",
            "M503",
                                           "M240 S0.01 Q0", "G4 S0.5",
            "A90.00 C0.00 M114 M503 P2",   "M240 S0.01 Q0", "G4 S0.5",
            "A90.00 C0.00 M114 M503 P2",   "M240 S0.01 Q0", "G4 S0.5",
            "A90.00 C0.00 M114 M503 P2",   "M240 S0.01 Q0", "G4 S0.5",
            "A90.00 C-51.00 M114 M503 P2", "M240 S0.01 Q0", "G4 S0.5",
            "A90.00 C0.00 M114 M503 P2",   "M240 S0.01 Q0", "G4 S0.5",
            "A90.00 C0.00 M114 M503 P2",   "M240 S0.01 Q0", "G4 S0.5",
            "A90.00 C0.00 M114 M503 P2",   "M240 S0.01 Q0", "G4 S0.5",
            "G0 G28",
            "M18 M114 M503"]
        for (gcodeLine, expectedLine) in zip(gcode, expected) {
            XCTAssertEqual(gcodeLine, expectedLine)
        }
    }

    /*
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
     */
    
}
