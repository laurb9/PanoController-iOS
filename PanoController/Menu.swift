//
//  Menu.swift
//  PanoController
//
//  Created by Laurentiu Badea on 7/30/17.
//  Copyright © 2017 Laurentiu Badea. All rights reserved.
//

import Foundation

class Option: NSObject {
    var name: String
    var value: Int
    var isDefault: Bool = false
    init(_ name: String, _ value: Int, isDefault: Bool = false){
        self.name = name
        self.value = value
        self.isDefault = isDefault
    }
}

class MenuItem: NSObject {
    var name: String
    init(_ name: String){
        self.name = name
    }
}

class ListSelector: MenuItem {
    var options: [Option]
    var current: Int = 0
    init(_ name: String, options: [Option]){
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
        super.init(name)
    }
    func currentOptionName() -> String {
        return options[current].name
    }
}

class RangeSelector: MenuItem {
    var min: Int
    var max: Int
    var current: Int
    init(_ name: String, min: Int, max: Int, defaultValue: Int){
        self.min = min
        self.max = max
        current = UserDefaults.standard.object(forKey: name) as? Int ?? defaultValue
        super.init(name)
    }
}

class Switch: MenuItem {
    var currentState: Bool
    init(_ name: String, _ defaultState: Bool){
        currentState = UserDefaults.standard.object(forKey: name) as? Bool ?? defaultState
        self.currentState = defaultState
        super.init(name)
    }
}

class ActionItem: MenuItem {

}

class Menu: NSObject {
    var name: String
    var entries: [MenuItem]
    init(_ name: String, entries: [MenuItem]){
        self.name = name
        self.entries = entries
    }
}

var menus = [
    Menu("🌄 Pano", entries: [
        ActionItem("New Pano"),
        ActionItem("Repeat Last"),
        ActionItem("360 Pano"),
        ActionItem("Last Pano Info"),
        RangeSelector("Horizontal FOV", min: 5, max: 360, defaultValue: 120),
        RangeSelector("Vertical FOV", min: 5, max: 180, defaultValue: 90),
        ]),
    Menu("📷️ Camera", entries: [
        ListSelector("Focal Length", options: [
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
        ListSelector("Shutter", options: [
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
        ListSelector("Delay", options: [
            Option("0.1s", 100, isDefault: true),
            Option("0.25s", 250),
            Option("0.5s", 500),
            Option("1s", 1000),
            Option("2s", 2000),
            Option("4s", 4000),
            Option("8s", 8000),
            ]),
        ListSelector("Processing Wait", options: [
            Option("0.1s", 100, isDefault: true),
            Option("0.25s", 250),
            Option("0.5s", 500),
            Option("1s", 1000),
            Option("2s", 2000),
            Option("4s", 4000),
            Option("8s", 8000),
            ]),
        ListSelector("Shutter Mode", options: [
            Option("Normal (Short)", 0, isDefault: true),
            Option("Cont Bracket (Long)", 1),
            ]),
        ListSelector("Shots #", options: [
            Option("1", 1, isDefault: true),
            Option("2", 2),
            Option("3", 3),
            Option("4", 4),
            Option("5", 5),
            ]),
        ListSelector("Aspect Ratio", options: [
            Option("Portrait 2:3", 23),
            Option("Landscape 3:2", 32, isDefault: true),
            ]),
    ]),
    Menu("🛠 Advanced", entries: [
        Switch("Motors", true),
        ]),
]
