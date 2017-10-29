//
//  PanoViewController.swift
//  PanoController
//
//  Created by Laurentiu Badea on 9/2/17.
//  Copyright © 2017 Laurentiu Badea. All rights reserved.
//

import UIKit

class PanoViewController: UIViewController, PanoPeripheralDelegate {
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
    var padViewController: PadViewController!
    var pano: Pano?
    var panoPeripheral: PanoPeripheral?

    override func viewDidLoad() {
        super.viewDidLoad()        // Do any additional setup after loading the view.
    }

    override func viewWillAppear(_ animated: Bool) {
        print("PanoViewControler: \(String(describing: panoPeripheral))")
        if let panoPeripheral = panoPeripheral,
            let pano = pano {
            panoPeripheral.delegate = self
            pano.panoPeripheralDidConnect(panoPeripheral)
            self.lensUILabel.text = "\(Int(pano.focalLength))"
            self.shutterUILabel.text = pano.shutter >= 0.25 ? "\(pano.shutter)s" : "1/\(Int(1/pano.shutter))s"
            self.horizUILabel.text = "\(pano.panoHorizFOV)"
            self.vertUILabel.text = "\(pano.panoVertFOV)"
            self.nameUILabel.text = panoPeripheral.name
            self.identifierUILabel.text = panoPeripheral.peripheral?.identifier.uuidString
            //self.signalUILabel.text = ...
            updateStatus()
        }
        setButtonStates(start: true, pause: false, cancel: false)
    }

    func updateStatus() {
        if let pano = pano {
            batteryUILabel.text = String(format: "%.1fV", arguments:[Float(pano.platform["Battery", default: "0"])!])
            motorsUILabel.text = Bool(pano.platform["MotorsEnabled"] ?? "false")! ? "⚡️" : "💤"
            rowsUILabel.text = "\(pano.rows)"
            colsUILabel.text = "\(pano.cols)"
            if pano.cols > 0 {
                currentRowUILabel.text = "\(pano.position / pano.cols + 1)"
                currentColUILabel.text = "\(pano.position % pano.cols + 1)"
                positionUILabel.text = "#\(pano.position + 1) of \(pano.rows * pano.cols)"
                if pano.state == .Idle {
                    panoUIProgressView.progress = 0.0
                } else {
                    panoUIProgressView.progress = Float(pano.position + 1) / Float(pano.rows * pano.cols)
                }
            }
            steadyDelayUILabel.text = String(format: "%.1fs", arguments:[Double(pano.platform["ZeroMotionWait", default: "0"])!])
            horizOffsetUILabel.text = pano.platform["CurrentA", default: "0"]
            vertOffsetUILabel.text = pano.platform["CurrentC", default: "0"]
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
                statusUILabel.text = "🕸"
                setButtonStates(start: padUIView.isHidden, pause: false, cancel: !padUIView.isHidden)
            }
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
    
    @IBAction func startPano(_ sender: UIButton) {
        showPadView(for: .freeMove)
        if let pano = pano, let panoPeripheral = panoPeripheral {
            pano.state = .Idle
            pano.panoPeripheralDidConnect(panoPeripheral) // triggers updateStatus() on receive
        }
    }
    @IBAction func pausePano(_ sender: UIButton) {
        //FIXME: ???
        showPadView(for: .gridMove)
        if let pano = pano, let panoPeripheral = panoPeripheral {
            pano.state = .Paused
            pano.panoPeripheralDidConnect(panoPeripheral) // triggers updateStatus() on receive
        }
    }
    @IBAction func cancelPano(_ sender: UIButton) {
        //FIXME: gcode, use Pano
        panoPeripheral?.writeLine("G0 G28")
        panoPeripheral?.writeLine("M18 M114 M503")
        pano?.state = .End
        hidePadView()
        setButtonStates(start: true, pause: false, cancel: false)
    }

    func showPadView(for moveMode: MoveMode) {
        padViewController.moveMode = moveMode
        if padUIView.isHidden {
            print("showing PadView in \(moveMode)")
            self.panoPeripheral?.writeLine("M17 M503 M114") // FIXME: gcode, use Pano
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
            padViewController.panoPeripheral = panoPeripheral
        }
    }

    @IBAction func unwindToStatus(sender: UIStoryboardSegue){
        print("unwindToStatus from \(sender)")
        hidePadView()
        if let panoPeripheral = panoPeripheral,
            let pano = pano,
            pano.state == .End || pano.state == .Idle {
            pano.startProgram(panoPeripheral)
        }
    }

    // MARK: - PanoPeripheralDelegate

    func panoPeripheralDidConnect(_ panoPeripheral: PanoPeripheral){
    }
    func panoPeripheralDidDisconnect(_ panoPeripheral: PanoPeripheral){
        performSegue(withIdentifier: "devices", sender: self)
    }
    func panoPeripheral(_ panoPeripheral: PanoPeripheral, didReceiveLine line: String) {
        pano?.panoPeripheral(panoPeripheral, didReceiveLine: line)
        updateStatus()
    }
}
