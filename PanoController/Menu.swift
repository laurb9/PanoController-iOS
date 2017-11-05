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

enum MenuItemKey {
    case horizFOV
    case vertFOV
    case focalLength
    case shutter
    case preShutter
    case postShutter
    case shutterLong
    case shotCount
    case aspect
    case infiniteRotation
    case zeroMotionWait
}

protocol MenuItemDelegate {
    func menuItem(didSet index: MenuItemKey, value: Any)
}

class Option: NSObject {
    let name: String
    let value: Any
    let isDefault: Bool
    init(_ name: String, _ value: Any, isDefault: Bool = false){
        self.name = name
        self.value = value
        self.isDefault = isDefault
    }
}

class MenuItem: NSObject {
    let name: String
    let key: MenuItemKey?
    let delegate: MenuItemDelegate?
    init(_ name: String, delegate: MenuItemDelegate? = nil, key: MenuItemKey? = nil){
        self.name = name
        self.delegate = delegate
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
                delegate?.menuItem(didSet: index, value: options[current].value)
            }
        }
    }
    init(_ name: String, delegate: MenuItemDelegate? = nil, key: MenuItemKey?, options: [Option]){
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
        super.init(name, delegate: delegate, key: key)
        if let index = key {
            delegate?.menuItem(didSet: index, value: options[current].value)
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
    let min: Int
    let max: Int
    var current: Int {
        didSet {
            UserDefaults.standard.set(current, forKey: name)
            if let index = key {
                delegate?.menuItem(didSet: index, value: current)
            }
        }
    }
    init(_ name: String, delegate: MenuItemDelegate? = nil, key: MenuItemKey?, min: Int, max: Int, defaultValue: Int){
        self.min = min
        self.max = max
        current = UserDefaults.standard.object(forKey: name) as? Int ?? defaultValue
        super.init(name, delegate: delegate, key: key)
        if let index = key {
            delegate?.menuItem(didSet: index, value: current)
        }
    }
}

class Switch: MenuItem {
    var currentState: Bool {
        didSet {
            UserDefaults.standard.set(currentState, forKey: name)
            if let index = key {
                delegate?.menuItem(didSet: index, value: currentState)
            }
        }
    }
    init(_ name: String, delegate: MenuItemDelegate? = nil, key: MenuItemKey?, _ defaultState: Bool){
        currentState = UserDefaults.standard.object(forKey: name) as? Bool ?? defaultState
        self.currentState = defaultState
        super.init(name, delegate: delegate, key: key)
        if let index = key {
            delegate?.menuItem(didSet: index, value: currentState)
        }
    }
}

class Menu: MenuItem {
    let entries: [MenuItem]
    var count: Int {
        return entries.count
    }
    init(_ name: String, delegate: MenuItemDelegate? = nil, entries: [MenuItem]){
        self.entries = entries
        super.init(name, delegate: delegate)
    }

    subscript(index: Int) -> MenuItem {
        return entries[index]
    }
    subscript(index: IndexPath) -> MenuItem {
        return (entries[index.section] as! Menu)[index.row]
    }
}

func getMenus(_ delegate: MenuItemDelegate) -> Menu {
    let menus = Menu("Configuration", delegate: delegate, entries: [
        Menu("🌄 Pano", delegate: delegate, entries: [
            RangeSelector("Horizontal FOV", delegate: delegate, key: .horizFOV, min: 5, max: 360, defaultValue: 120),
            RangeSelector("Vertical FOV", delegate: delegate, key: .vertFOV, min: 5, max: 180, defaultValue: 90),
            ]),
        Menu("📷️ Camera", delegate: delegate, entries: [
            ListSelector("Focal Length", delegate: delegate, key: .focalLength, options: [
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
            ListSelector("Shutter", delegate: delegate, key: .shutter, options: [
                Option("1/1000s", 1.0/1000),
                Option("1/500s", 1.0/500),
                Option("1/250s", 1.0/250),
                Option("1/100s", 1.0/100, isDefault: true),
                Option("1/50s", 1.0/50),
                Option("1/25s", 1.0/25),
                Option("1/10s", 1.0/10),
                Option("1/4s", 1.0/4),
                Option("0.5s", 0.5),
                Option("1s", 1.0),
                Option("2s", 2.0),
                Option("4s", 4.0),
                Option("8s", 8.0),
                Option("BULB", 0),
                ]),
            ListSelector("Pre-Shot Delay", delegate: delegate, key: .preShutter, options: [
                Option("None", 0.0),
                Option("0.1s", 0.1, isDefault: true),
                Option("0.25s", 0.25),
                Option("0.5s", 0.5),
                Option("1s", 1.0),
                Option("2s", 2.0),
                Option("4s", 4.0),
                Option("8s", 8.0),
                ]),
            ListSelector("Post-Shot Delay", delegate: delegate, key: .postShutter, options: [
                Option("None", 0.0),
                Option("0.1s", 0.1, isDefault: true),
                Option("0.25s", 0.25),
                Option("0.5s", 0.5),
                Option("1s", 1.0),
                Option("2s", 2.0),
                Option("4s", 4.0),
                Option("8s", 8.0),
                ]),
            ListSelector("Shutter Mode", delegate: delegate, key: .shutterLong, options: [
                Option("Normal (Short)", false, isDefault: true),
                Option("Cont Bracket (Long)", true),
                ]),
            ListSelector("Shots #", delegate: delegate, key: .shotCount, options: [
                Option("1", 1, isDefault: true),
                Option("2", 2),
                Option("3", 3),
                Option("4", 4),
                Option("5", 5),
                ]),
            ListSelector("Aspect Ratio", delegate: delegate, key: .aspect, options: [
                Option("Portrait 2:3", 23),
                Option("Landscape 3:2", 32, isDefault: true),
                ]),
        ]),
        Menu("🛠 Advanced", delegate: delegate, entries: [
            ListSelector("Zero Motion Wait", delegate: delegate, key: .zeroMotionWait, options: [
                Option("Disabled", 0.0),
                Option("1s", 1.0),
                Option("5s", 5.0),
                Option("10s", 10.0, isDefault: true),
                Option("30s", 30.0),
                ]),
            Switch("Infinite Rotation", delegate: delegate, key: .infiniteRotation, false),
            Switch("Motors", delegate: delegate, key: nil, false),
            ]),
    ])
    return menus
}
