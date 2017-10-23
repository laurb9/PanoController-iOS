//
//  PanoControllerTests.swift
//  PanoControllerTests
//
//  Created by Laurentiu Badea on 7/30/17.
//  Copyright © 2017 Laurentiu Badea. All rights reserved.
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

    func testCameraLensFOV(){
        XCTAssertEqual(Pano.lensFOV(for: 36, at: 8), 132.08, accuracy: 0.01)
        XCTAssertEqual(Pano.lensFOV(for: 36, at: 24), 73.74, accuracy: 0.01)
        XCTAssertEqual(Pano.lensFOV(for: 24, at: 600), 2.29, accuracy: 0.01)
        XCTAssertEqual(Pano.lensFOV(for: 3.6, at: 8.0), 25.36, accuracy: 0.01)
        XCTAssertEqual(Pano.lensFOV(for: 3.0, at: 2.4), 64.01, accuracy: 0.01)
    }

    func testPanoComputeGrid(){

        // 360 pano
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
        let gcode = pano.gCode()
        XCTAssertEqual(gcode,
                       ["M17 G1 G91 G92 A0 C0",
                        "A0.00 C0.00", "M116 P10 Q11", "M240 P0.01 Q0 R0",
                        "A4.31 C0.00", "M116 P10 Q11", "M240 P0.01 Q0 R0",
                        "A-4.31 C-3.03", "M116 P10 Q11", "M240 P0.01 Q0 R0",
                        "A4.31 C0.00", "M116 P10 Q11", "M240 P0.01 Q0 R0",
                        "A-4.31 C-3.03", "M116 P10 Q11", "M240 P0.01 Q0 R0",
                        "A4.31 C0.00", "M116 P10 Q11", "M240 P0.01 Q0 R0",
                        "G0 G28", "M18"])
    }

    func test360PanoGCode() {
        pano.panoHorizFOV = 360
        pano.panoVertFOV = 120
        pano.focalLength = 12.00
        pano.overlap = 0.2
        pano.shutter = 1/100
        pano.preShutter = 0
        pano.postShutter = 0.5
        let gcode = pano.gCode()
        XCTAssertEqual(gcode,
                       ["M17 G1 G91 G92 A0 C0",
                        "A0.00 C0.00", "M116 P10 Q225", "M240 P0.01 Q0 R0.5",
                        "A90.00 C0.00", "M116 P10 Q225", "M240 P0.01 Q0 R0.5",
                        "A90.00 C0.00", "M116 P10 Q225", "M240 P0.01 Q0 R0.5",
                        "A90.00 C0.00", "M116 P10 Q225", "M240 P0.01 Q0 R0.5",
                        "A90.00 C-51.00", "M116 P10 Q225", "M240 P0.01 Q0 R0.5",
                        "A90.00 C0.00", "M116 P10 Q225", "M240 P0.01 Q0 R0.5",
                        "A90.00 C0.00", "M116 P10 Q225", "M240 P0.01 Q0 R0.5",
                        "A90.00 C0.00", "M116 P10 Q225", "M240 P0.01 Q0 R0.5",
                        "G0 G28", "M18"])
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
