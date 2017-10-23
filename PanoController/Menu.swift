//
//  Menu.swift
//  PanoController
//
//  Created by Laurentiu Badea on 7/30/17.
//  Copyright © 2017 Laurentiu Badea.
//
//  This file may be redistributed under the terms of the MIT license.
//  A copy of this license has been included with this distribution in the file LICENSE.
//

import Foundation

class Option: NSObject {
    let name: String
    let value: Int16
    let isDefault: Bool
    init(_ name: String, _ value: Int16, isDefault: Bool = false){
        self.name = name
        self.value = value
        self.isDefault = isDefault
    }
}

class MenuItem: NSObject {
    let name: String
    let config: Config
    let key: String?
    init(_ name: String, using config: Config, key: String? = nil){
        self.name = name
        self.config = config
        self.key = key
    }
}

class ListSelector: MenuItem {
    let options: [Option]
    var count: Int {
        return options.count
    }
    var current: Int = 0 {
        didSet {
            UserDefaults.standard.set(current, forKey: name)
            if let index = key {
                config[index] = options[current].value
            }
        }
    }
    init(_ name: String, using config: Config, key: String?, options: [Option]){
        self.options = options
        if let savedCurrent = UserDefaults.standard.object(forKey: name) as? Int {
            current = savedCurrent
        } else {
            for i in 0..<options.count {
                if options[i].isDefault {
                    current = i
                    break
                }
            }
        }
        super.init(name, using: config, key: key)
        if let index = key {
            config[index] = options[current].value
        }
    }
    func currentOptionName() -> String {
        return self[current].name
    }
    subscript(index: Int) -> Option {
        return options[index]
    }
}

class RangeSelector: MenuItem {
    let min: Int16
    let max: Int16
    var current: Int16 {
        didSet {
            UserDefaults.standard.set(current, forKey: name)
            if let index = key {
                config[index] = current
            }
        }
    }
    init(_ name: String, using config: Config, key: String?, min: Int16, max: Int16, defaultValue: Int16){
        self.min = min
        self.max = max
        current = UserDefaults.standard.object(forKey: name) as? Int16 ?? defaultValue
        super.init(name, using: config, key: key)
        if let index = key {
            config[index] = current
        }
    }
}

class Switch: MenuItem {
    var currentState: Bool {
        didSet {
            UserDefaults.standard.set(currentState, forKey: name)
            if let index = key {
                config[index] = currentState ? 1 : 0
            }
        }
    }
    init(_ name: String, using config: Config, key: String?, _ defaultState: Bool){
        currentState = UserDefaults.standard.object(forKey: name) as? Bool ?? defaultState
        self.currentState = defaultState
        super.init(name, using: config, key: key)
        if let index = key {
            config[index] = currentState ? 1 : 0
        }
    }
}

class Menu: MenuItem {
    let entries: [MenuItem]
    var count: Int {
        return entries.count
    }
    init(_ name: String, using config: Config, entries: [MenuItem]){
        self.entries = entries
        super.init(name, using: config)
    }

    subscript(index: Int) -> MenuItem {
        return entries[index]
    }
    subscript(index: IndexPath) -> MenuItem {
        return (entries[index.section] as! Menu)[index.row]
    }
}

func getMenus(_ config: Config) -> Menu {
    let menus = Menu("Configuration", using: config, entries: [
        Menu("🌄 Pano", using: config, entries: [
            RangeSelector("Horizontal FOV", using: config, key: "horiz", min: 5, max: 360, defaultValue: 120),
            RangeSelector("Vertical FOV", using: config, key: "vert", min: 5, max: 180, defaultValue: 90),
            ]),
        Menu("📷️ Camera", using: config, entries: [
            ListSelector("Focal Length", using: config, key: "focal", options: [
                Option("12mm", 12),
                Option("14mm", 14),
                Option("16mm", 16),
                Option("20mm", 20),
                Option("24mm", 24),
                Option("28mm", 28),
                Option("35mm", 35, isDefault: true),
                Option("50mm", 50),
                Option("75mm", 75),
                Option("105mm", 105),
                Option("200mm", 200),
                Option("300mm", 300),
                Option("400mm", 400),
                Option("450mm", 450),
                Option("500mm", 500),
                Option("600mm", 600),
                ]),
            ListSelector("Shutter", using: config, key: "shutter", options: [
                Option("1/1000s", 1),
                Option("1/500s", 2),
                Option("1/250s", 4),
                Option("1/100s", 10, isDefault: true),
                Option("1/50s", 20),
                Option("1/25s", 40),
                Option("1/10s", 100),
                Option("1/4s", 250),
                Option("0.5s", 500),
                Option("1s", 1000),
                Option("2s", 2000),
                Option("4s", 4000),
                Option("8s", 8000),
                Option("BULB", 0),
                ]),
            ListSelector("Delay", using: config, key: "pre_shutter", options: [
                Option("0.1s", 100, isDefault: true),
                Option("0.25s", 250),
                Option("0.5s", 500),
                Option("1s", 1000),
                Option("2s", 2000),
                Option("4s", 4000),
                Option("8s", 8000),
                ]),
            ListSelector("Processing Wait", using: config, key: "post_wait", options: [
                Option("0.1s", 100, isDefault: true),
                Option("0.25s", 250),
                Option("0.5s", 500),
                Option("1s", 1000),
                Option("2s", 2000),
                Option("4s", 4000),
                Option("8s", 8000),
                ]),
            ListSelector("Shutter Mode", using: config, key: "long_pulse", options: [
                Option("Normal (Short)", 0, isDefault: true),
                Option("Cont Bracket (Long)", 1),
                ]),
            ListSelector("Shots #", using: config, key: "shots", options: [
                Option("1", 1, isDefault: true),
                Option("2", 2),
                Option("3", 3),
                Option("4", 4),
                Option("5", 5),
                ]),
            ListSelector("Aspect Ratio", using: config, key: "aspect", options: [
                Option("Portrait 2:3", 23),
                Option("Landscape 3:2", 32, isDefault: true),
                ]),
        ]),
        Menu("🛠 Advanced", using: config, entries: [
            Switch("Motors", using: config, key: "motors_on", false),
            ]),
    ])
    return menus
}
