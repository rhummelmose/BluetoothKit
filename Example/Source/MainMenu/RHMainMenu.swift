//
//  RHMainMenu.swift
//  BKExample
//
//  Created by Rasmus H. Hummelmose on 16/11/2016.
//  Copyright © 2016 Rasmus Høhndorf Hummelmose. All rights reserved.
//

import Cocoa

public class RHMainMenu: NSMenu {
    
    // MARK: Properties
    
    public let applicationMenu = NSMenuItem(title: "Application", action: nil, keyEquivalent: "")
    public var fileMenu: NSMenuItem?
    public var editMenu: NSMenuItem?
    public var formatMenu: NSMenuItem?
    public var viewMenu: NSMenuItem?
    public var windowMenu: NSMenuItem?
    public var helpMenu: NSMenuItem?
    
    // MARK: Initialization
    
    public convenience init() {
        self.init(title: "Main Menu")
    }
    
    public override init(title: String) {
        super.init(title: title)
    }
    
    required public init(coder decoder: NSCoder) {
        fatalError("Interface builder... really?")
    }
    
}
