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

    var panoPeripheral: PanoPeripheral?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
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
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func startPano(_ sender: UIButton) {
        panoPeripheral?.send(command: "Start")
    }
    @IBAction func pausePano(_ sender: UIButton) {
        panoPeripheral?.send(command: "Pause")
    }
    @IBAction func cancelPano(_ sender: UIButton) {
        panoPeripheral?.send(command: "Cancel")
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

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
            positionUILabel.text = "\(status.position+1)"
            steadyDelayUILabel.text = String(format: "%.1f s", arguments:[Float(status.steady_delay_avg)/1000.0])
            horizOffsetUILabel.text = String(format: "%.1fº", arguments:[status.horiz_offset])
            vertOffsetUILabel.text = String(format: "%.1fº", arguments:[status.vert_offset])
        } else {
            positionUILabel.text = "N/A"
            steadyDelayUILabel.text = "N/A"
            horizOffsetUILabel.text = "0"
            vertOffsetUILabel.text = "0"
        }
        switch (status.running, status.paused) {
        case (1, 0):
            statusUILabel.text = " RUNNING"
            startUIButton.isEnabled = false
            pauseUIButton.isEnabled = true
            cancelUIButton.isEnabled = true
        case (1, 1):
            statusUILabel.text = "PAUSED"
            startUIButton.isEnabled = true
            pauseUIButton.isEnabled = false
            cancelUIButton.isEnabled = true
        default:
            statusUILabel.text = "ready"
            startUIButton.isEnabled = true
            pauseUIButton.isEnabled = false
            cancelUIButton.isEnabled = false
        }
    }
}
