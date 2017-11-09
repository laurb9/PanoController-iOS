	//
//  PanoViewController.swift
//  PanoController
//
//  Created by Laurentiu Badea on 9/2/17.
//  Copyright © 2017 Laurentiu Badea. All rights reserved.
//

import CoreBluetooth
import UIKit

class PanoViewController: UIViewController {
    @IBOutlet weak var nameUILabel: UILabel!
    @IBOutlet weak var identifierUILabel: UILabel!
    @IBOutlet weak var panoUIProgressView: UIProgressView!
    @IBOutlet weak var batteryUILabel: UILabel!
    @IBOutlet weak var positionUILabel: UILabel!
    @IBOutlet weak var rowsUILabel: UILabel!
    @IBOutlet weak var colsUILabel: UILabel!
    @IBOutlet weak var currentRowUILabel: UILabel!
    @IBOutlet weak var currentColUILabel: UILabel!
    @IBOutlet weak var statusUILabel: UILabel!
    @IBOutlet weak var motorsUILabel: UILabel!
    @IBOutlet weak var steadyDelayUILabel: UILabel!
    @IBOutlet weak var horizOffsetUILabel: UILabel!
    @IBOutlet weak var vertOffsetUILabel: UILabel!
    @IBOutlet weak var startUIButton: UIButton!
    @IBOutlet weak var pauseUIButton: UIButton!
    @IBOutlet weak var cancelUIButton: UIButton!
    @IBOutlet weak var signalUILabel: UILabel!
    @IBOutlet weak var lensUILabel: UILabel!
    @IBOutlet weak var shutterUILabel: UILabel!
    @IBOutlet weak var horizUILabel: UILabel!
    @IBOutlet weak var vertUILabel: UILabel!
    @IBOutlet weak var padUIView: UIView!
    @IBOutlet weak var connectUIButton: UIButton!
    var padViewController: PadViewController!
    var bleManager: BLEManager!
    var pano: Pano!
    var menus: Menu!

    override func viewDidLoad() {
        super.viewDidLoad()
        bleManager = BLEManager(delegate: self)
        pano = Pano()
        menus = getMenus(pano)    // kind of doesn't belong here, but it loads the saved settings
        pano.computeGrid()        // recalculate grid after loading saved settings
    }

    override func viewWillAppear(_ animated: Bool) {
        print("PanoViewControler: \(String(describing: bleManager))")
        bleManager.delegate = self
        // These are updated in a different view so we don't need to render in updateStatus()
        self.lensUILabel.text = "\(Int(pano.focalLength))"
        self.shutterUILabel.text = pano.shutter >= 0.5 ? "\(pano.shutter)s" : "1/\(Int(1/pano.shutter))s"
        self.horizUILabel.text = "\(pano.panoHorizFOV)"
        self.vertUILabel.text = "\(pano.panoVertFOV)"
        updateStatus()
    }

    func updateStatus() {
        if let panoPeripheral = bleManager.panoPeripheral {
            self.nameUILabel.text = pano.platform["Name", default: panoPeripheral.name] + " " + pano.platform["Version", default: ""]
            self.identifierUILabel.text = pano.platform["Build", default: panoPeripheral.peripheral?.identifier.uuidString ?? ""]
            if let battery = Float(pano.platform["Battery", default: ""]) {
                batteryUILabel.text = String(format: "%.1fV", arguments:[battery])
            }
            if let steadyDelay = Float(pano.platform["ZeroMotionWait", default: ""]) {
                steadyDelayUILabel.text = String(format: "%.1fs", arguments:[steadyDelay])
            }
            motorsUILabel.text = Bool(pano.platform["MotorsEnabled"] ?? "false")! ? "⚡️" : "💤"

            switch pano.state {
            case .Running:
                statusUILabel.text = "▶️"
                setButtonStates(start: false, pause: true, cancel: true)
            case .Paused:
                statusUILabel.text = "⏸"
                setButtonStates(start: false, pause: false, cancel: true)
                showPadView(for: .gridMove)
            case .End:
                statusUILabel.text = "⏹"
                setButtonStates(start: true, pause: false, cancel: false)
            default:
                statusUILabel.text = " "
                setButtonStates(start: padUIView.isHidden, pause: false, cancel: !padUIView.isHidden)
            }

        } else {
            nameUILabel.text = ""
            identifierUILabel.text = "\(bleManager.peripherals.count) devices found"
            batteryUILabel.text = ""
            steadyDelayUILabel.text = ""
            motorsUILabel.text = ""
            statusUILabel.text = ""
            setButtonStates(start: false, pause: false, cancel: false)
        }

        horizOffsetUILabel.text = pano.platform["CurrentA", default: "0"]
        vertOffsetUILabel.text = pano.platform["CurrentC", default: "0"]
        rowsUILabel.text = "\(pano.rows)"
        colsUILabel.text = "\(pano.cols)"

        currentRowUILabel.text = "\(pano.position / pano.cols + 1)"
        currentColUILabel.text = "\(pano.position % pano.cols + 1)"
        positionUILabel.text = "#\(pano.position + 1) of \(pano.rows * pano.cols)"

        if pano.state == .Idle {
            panoUIProgressView.progress = 0.0
        } else {
            panoUIProgressView.progress = Float(pano.position + 1) / Float(pano.rows * pano.cols)
        }
    }

    func setButtonStates(start: Bool, pause: Bool, cancel: Bool){
        startUIButton.isEnabled = start
        pauseUIButton.isEnabled = pause
        cancelUIButton.isEnabled = cancel
        for button: UIButton in [startUIButton, pauseUIButton, cancelUIButton]{
            button.alpha = button.isEnabled ? 1.0 : 0.1
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Button actions

    @IBAction func startPano(_ sender: UIButton) {
        showPadView(for: .freeMove)
        if let panoPeripheral = bleManager.panoPeripheral {
            pano.state = .Idle
            pano.panoPeripheralDidConnect(panoPeripheral) // triggers updateStatus() on receive
        }
    }
    @IBAction func pausePano(_ sender: UIButton) {
        //FIXME: ???
        showPadView(for: .gridMove)
        if let panoPeripheral = bleManager.panoPeripheral {
            pano.state = .Paused
            pano.panoPeripheralDidConnect(panoPeripheral) // triggers updateStatus() on receive
        }
    }
    @IBAction func cancelPano(_ sender: UIButton) {
        //FIXME: gcode, use Pano
        bleManager.panoPeripheral?.writeLine("G0 G28")
        bleManager.panoPeripheral?.writeLine("M18 M114 M503")
        pano.state = .End
        hidePadView()
        setButtonStates(start: true, pause: false, cancel: false)
    }
    @IBAction func connectButton(_ sender: UIButton) {
    }

    func showPadView(for moveMode: MoveMode) {
        padViewController.bleManager = bleManager
        padViewController.moveMode = moveMode
        if padUIView.isHidden {
            print("showing PadView in \(moveMode)")
            bleManager.panoPeripheral?.writeLine("M17 G1 G91 M503 M114 M203 A10 C10 M321") // FIXME: gcode, use Pano
            padUIView.isHidden = false
            UIView.animate(withDuration: 0.5, animations: { self.padUIView.alpha = 1 })
        }
    }

    func hidePadView() {
        if !padUIView.isHidden {
            print("dismiss PadView")
            UIView.animate(withDuration: 0.5, animations: {
                self.padUIView.alpha = 0
            }, completion: {
                (_: Bool) in
                    self.padUIView.isHidden = true
            })
        }
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let padViewController = segue.destination as? PadViewController {
            self.padViewController = padViewController
        } else if let menuTableViewController = segue.destination as? MenuTableViewController {
            menuTableViewController.menus = menus
        } else if let deviceTableViewController = segue.destination as? DeviceTableViewController {
            deviceTableViewController.bleManager = bleManager
            deviceTableViewController.delegate = self
        }
    }

    @IBAction func unwindToPano(sender: UIStoryboardSegue){
        print("unwindToPano from \(sender)")
        if sender.source is PadViewController {
            hidePadView()
            if let panoPeripheral = bleManager.panoPeripheral,
                pano.state == .End || pano.state == .Idle {
                pano.startProgram(panoPeripheral)
            }
        } else if sender.source is DeviceTableViewController {
            bleManager.delegate = self
        }
    }
}

// MARK: - BLEManagerDelegate

extension PanoViewController : BLEManagerDelegate {
    func bleManager(_ ble: BLEManager, didConnect panoPeripheral: PanoPeripheral) {
        panoPeripheral.delegate = self
        pano.panoPeripheralDidConnect(panoPeripheral)
        updateStatus()
    }

    func bleManager(_ ble: BLEManager, didDisconnect panoPeripheral: PanoPeripheral) {
        pano.panoPeripheralDidDisconnect(panoPeripheral)
        updateStatus()
    }

    func bleManager(_ ble: BLEManager, didDiscover peripheral: CBPeripheral) {
    }

    func bleManager(_ ble: BLEManager, didReceiveLine line: String) {
    }
}

// MARK: - DeviceTableViewControllerDelegate

extension PanoViewController : DeviceTableViewControllerDelegate {
    func deviceTableViewController(_ deviceTableViewController: DeviceTableViewController, didConnect panoPeripheral: PanoPeripheral) {
        panoPeripheral.delegate = self
        pano.panoPeripheralDidConnect(panoPeripheral)
    }

    func deviceTableViewController(_ deviceTableViewController: DeviceTableViewController, didDisconnect panoPeripheral: PanoPeripheral) {
        pano.panoPeripheralDidDisconnect(panoPeripheral)
    }
}

// MARK: - PanoPeripheralDelegate

extension PanoViewController : PanoPeripheralDelegate {
    func panoPeripheralDidConnect(_ panoPeripheral: PanoPeripheral){
    }

    func panoPeripheralDidDisconnect(_ panoPeripheral: PanoPeripheral){
    }

    func panoPeripheral(_ panoPeripheral: PanoPeripheral, didReceiveLine line: String) {
        pano.panoPeripheral(panoPeripheral, didReceiveLine: line)
        updateStatus()
    }
}
