//
//  PadViewController.swift
//  PanoController
//
//  Created by Laurentiu Badea on 9/4/17.
//  Copyright © 2017 Laurentiu Badea. All rights reserved.
//

import UIKit

class PadViewController: UIViewController {
    var panoPeripheral: PanoPeripheral?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func viewWillAppear(_ animated: Bool) {
        print("PadViewControler: \(String(describing: panoPeripheral))")
        //if let panoPeripheral = panoPeripheral {
        //    panoPeripheral.delegate = self
        //}
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    @IBAction func arrowLeft(_ sender: UIButton) {
        panoPeripheral?.sendIncMove(forward: false)
    }

    @IBAction func arrowRight(_ sender: UIButton) {
        panoPeripheral?.sendIncMove(forward: true)
    }

    @IBAction func arrowUp(_ sender: UIButton) {
    }
    @IBAction func arrowDown(_ sender: UIButton) {
    }
}
