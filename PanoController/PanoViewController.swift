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
    @IBOutlet weak var batteryUILabel: UILabel!
    @IBOutlet weak var positionUILabel: UILabel!
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
    var panoPeripheral: PanoPeripheral?

    override func viewDidLoad() {
        super.viewDidLoad()        // Do any additional setup after loading the view.
    }

    override func viewWillAppear(_ animated: Bool) {
        print("PanoViewControler: \(String(describing: panoPeripheral))")
        if let panoPeripheral = panoPeripheral {
            panoPeripheral.delegate = self
            self.nameUILabel.text = panoPeripheral.name
            self.lensUILabel.text = "\(panoPeripheral.config["focal"])mm"
            self.shutterUILabel.text = "\(panoPeripheral.config["shutter"])ms"
            self.horizUILabel.text = "\(panoPeripheral.config["horiz"])º"
            self.vertUILabel.text = "\(panoPeripheral.config["vert"])º"
            self.identifierUILabel.text = panoPeripheral.peripheral?.identifier.uuidString
            //self.signalUILabel.text = ...
        }
        setButtonStates(start: true, pause: false, cancel: false)
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
        setButtonStates(start: false, pause: false, cancel: true)
    }
    @IBAction func pausePano(_ sender: UIButton) {
        panoPeripheral?.send(command: .pause)
        showPadView(for: .gridMove)
        setButtonStates(start: false, pause: false, cancel: true)
    }
    @IBAction func cancelPano(_ sender: UIButton) {
        panoPeripheral?.send(command: .cancel)
        hidePadView()
        setButtonStates(start: true, pause: false, cancel: false)
    }

    func showPadView(for moveMode: MoveMode) {
        padViewController.moveMode = moveMode
        if padUIView.isHidden {
            print("showing PadView in \(moveMode)")
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
        panoPeripheral?.send(command: .start)
        hidePadView()
    }

    // MARK: - PanoPeripheralDelegate

    func panoPeripheralDidConnect(_ panoPeripheral: PanoPeripheral){
    }
    func panoPeripheralDidDisconnect(_ panoPeripheral: PanoPeripheral){
        performSegue(withIdentifier: "devices", sender: self)
    }
    func panoPeripheral(_ panoPeripheral: PanoPeripheral, didReceiveStatus status: Status){
        batteryUILabel.text = String(format: "%.1f V", arguments:[Float(abs(status.battery))/1000.0])
        motorsUILabel.text = status.motors_on == 1 ? "ON" : "off"
        if status.running == 1 {
            positionUILabel.text = "\(status.position+1) of \(status.rows*status.cols)"
            steadyDelayUILabel.text = String(format: "%.1f s", arguments:[Float(status.steady_delay_avg)/1000.0])
            horizOffsetUILabel.text = "\(status.horiz_offset)"
            vertOffsetUILabel.text = "\(status.vert_offset)"
        } else {
            positionUILabel.text = "N/A"
            steadyDelayUILabel.text = "N/A"
            horizOffsetUILabel.text = "0"
            vertOffsetUILabel.text = "0"
        }
        switch (status.running, status.paused) {
        case (1, 0):
            statusUILabel.text = " RUNNING"
            setButtonStates(start: false, pause: true, cancel: true)
        case (1, 1):
            statusUILabel.text = "PAUSED"
            setButtonStates(start: false, pause: false, cancel: true)
        default:
            statusUILabel.text = "ready"
        }
        if status.running == 1 && status.paused == 1 {
            showPadView(for: .gridMove)
        }
    }
}
